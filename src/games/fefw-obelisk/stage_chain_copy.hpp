/*
 * Copyright (C) 2026 y9999
 * SPDX-License-Identifier: MIT
 */

#pragma once

// Obelisk Chamber gives every shader stage the same `static const VkPipelineRobustnessCreateInfoEXT` as
// its pNext ([nvn] robust_ubo, on by default). When an add-on replaces a shader, ReShade rebuilds the
// pipeline from the game's create info and appends a VkShaderModuleCreateInfo to the end of each stage's
// pNext chain, which writes the pNext of that shared read-only struct: an access violation. Because the
// struct is shared, making it writable would not be enough either: the stages of one pipeline, and the
// pipelines other threads build at the same moment, would all see the same appended node.
//
// The game's call to vkCreateGraphicsPipelines is therefore passed on with private, writable copies of
// each stage and of the structs in its pNext chain. Nothing else changes: the copies carry the same
// values, ReShade restores the links it wrote before the call returns, and the copies live until then.

#include <windows.h>

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <string>
#include <vector>

#include <include/reshade.hpp>

#include "../../utils/minhook.hpp"

namespace fefw::stage_chain_copy {

namespace vk {
// Vulkan 1.3 x64 layouts of the structs read here (the add-on build has no Vulkan headers).
struct BaseInStructure {
  int32_t sType;
  const void* pNext;
};

struct PipelineShaderStageCreateInfo {
  int32_t sType;
  const void* pNext;
  uint32_t flags;
  uint32_t stage;
  uint64_t module;
  const char* pName;
  const void* pSpecializationInfo;
};
static_assert(sizeof(PipelineShaderStageCreateInfo) == 48);

struct GraphicsPipelineCreateInfo {
  int32_t sType;
  const void* pNext;
  uint32_t flags;
  uint32_t stageCount;
  const PipelineShaderStageCreateInfo* pStages;
  const void* states[9];  // pVertexInputState .. pDynamicState
  uint64_t layout;
  uint64_t renderPass;
  uint32_t subpass;
  uint64_t basePipelineHandle;
  int32_t basePipelineIndex;
};
static_assert(sizeof(GraphicsPipelineCreateInfo) == 144);
static_assert(offsetof(GraphicsPipelineCreateInfo, pStages) == 24);
static_assert(offsetof(GraphicsPipelineCreateInfo, layout) == 104);

using PFN_vkCreateGraphicsPipelines = int32_t (*)(void* device, uint64_t pipeline_cache, uint32_t count,
                                                  const GraphicsPipelineCreateInfo* create_infos,
                                                  const void* allocator, uint64_t* pipelines);
using PFN_vkGetDeviceProcAddr = void* (*)(void* device, const char* name);

constexpr int32_t STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO = 16;
constexpr int32_t STRUCTURE_TYPE_PIPELINE_ROBUSTNESS_CREATE_INFO = 1000068000;
constexpr int32_t STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO = 1000225001;
}  // namespace vk

namespace internal {

// Storage for one copied chain struct; every struct copied here fits.
struct alignas(8) NodeStorage {
  std::byte bytes[64];
};

static vk::PFN_vkCreateGraphicsPipelines original_create_graphics_pipelines = nullptr;
static void* hooked_target = nullptr;

static int32_t CreateGraphicsPipelines(void* device, uint64_t pipeline_cache, uint32_t count,
                                       const vk::GraphicsPipelineCreateInfo* create_infos,
                                       const void* allocator, uint64_t* pipelines) {
  if (count == 0u || create_infos == nullptr) {
    return original_create_graphics_pipelines(device, pipeline_cache, count, create_infos, allocator, pipelines);
  }

  size_t stage_count = 0u;
  size_t node_count = 0u;
  for (uint32_t i = 0; i < count; ++i) {
    const auto& info = create_infos[i];
    if (info.pStages == nullptr) continue;
    stage_count += info.stageCount;
    for (uint32_t k = 0; k < info.stageCount; ++k) {
      for (auto* node = static_cast<const vk::BaseInStructure*>(info.pStages[k].pNext); node != nullptr;
           node = static_cast<const vk::BaseInStructure*>(node->pNext)) {
        ++node_count;
      }
    }
  }
  // No stage has an extension: there is nothing ReShade could write into.
  if (node_count == 0u) {
    return original_create_graphics_pipelines(device, pipeline_cache, count, create_infos, allocator, pipelines);
  }

  std::vector<vk::GraphicsPipelineCreateInfo> infos(create_infos, create_infos + count);
  std::vector<vk::PipelineShaderStageCreateInfo> stages(stage_count);
  std::vector<NodeStorage> nodes(node_count);
  size_t stage_index = 0u;
  size_t node_index = 0u;

  for (auto& info : infos) {
    if (info.pStages == nullptr || info.stageCount == 0u) continue;
    auto* first_stage = &stages[stage_index];
    for (uint32_t k = 0; k < info.stageCount; ++k) {
      auto& stage = stages[stage_index++];
      stage = info.pStages[k];
      const void** link = &stage.pNext;
      for (auto* node = static_cast<const vk::BaseInStructure*>(info.pStages[k].pNext); node != nullptr;
           node = static_cast<const vk::BaseInStructure*>(node->pNext)) {
        // Sizes of the stage extensions Obelisk Chamber chains, and of the one ReShade looks for.
        size_t size = 0u;
        switch (node->sType) {
          case vk::STRUCTURE_TYPE_PIPELINE_ROBUSTNESS_CREATE_INFO:
            size = 32u;  // sType, pNext, four behaviour enums
            break;
          case vk::STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO:
            size = 24u;  // sType, pNext, requiredSubgroupSize
            break;
          case vk::STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO:
            size = 40u;  // sType, pNext, flags, codeSize, pCode
            break;
          default:
            break;
        }
        if (size == 0u) {
          *link = node;  // An unknown struct: keep it and what follows it as the game made them.
          break;
        }
        auto* copy = reinterpret_cast<vk::BaseInStructure*>(nodes[node_index++].bytes);
        std::memcpy(copy, node, size);
        copy->pNext = nullptr;
        *link = copy;
        link = &copy->pNext;
      }
    }
    info.pStages = first_stage;
  }

  return original_create_graphics_pipelines(device, pipeline_cache, count, infos.data(), allocator, pipelines);
}

}  // namespace internal

// Hooks the vkCreateGraphicsPipelines the game calls (ReShade's), once, when the Vulkan device is made.
static void OnInitDevice(reshade::api::device* device) {
  if (device->get_api() != reshade::api::device_api::vulkan) return;
  if (internal::hooked_target != nullptr) return;

  HMODULE loader = GetModuleHandleW(L"vulkan-1.dll");
  if (loader == nullptr) {
    reshade::log::message(reshade::log::level::error, "fefw: vulkan-1.dll is not loaded; stage chains are not copied.");
    return;
  }
  auto get_device_proc_addr = reinterpret_cast<vk::PFN_vkGetDeviceProcAddr>(
      reinterpret_cast<void*>(GetProcAddress(loader, "vkGetDeviceProcAddr")));
  if (get_device_proc_addr == nullptr) return;

  void* native_device = reinterpret_cast<void*>(static_cast<uintptr_t>(device->get_native()));
  void* target = get_device_proc_addr(native_device, "vkCreateGraphicsPipelines");
  if (target == nullptr) {
    reshade::log::message(reshade::log::level::error, "fefw: vkCreateGraphicsPipelines not found; stage chains are not copied.");
    return;
  }

  try {
    const renodx::utils::minhook::Function hook(
        reinterpret_cast<vk::PFN_vkCreateGraphicsPipelines>(target), &internal::CreateGraphicsPipelines,
        &internal::original_create_graphics_pipelines);
    renodx::utils::minhook::Initialize();
    renodx::utils::minhook::Create(hook);
    renodx::utils::minhook::Enable(hook);
  } catch (const std::exception& error) {
    reshade::log::message(reshade::log::level::error,
                          (std::string("fefw: hooking vkCreateGraphicsPipelines failed (") + error.what()
                           + "); stage chains are not copied.")
                              .c_str());
    return;
  }
  internal::hooked_target = target;

  char module_name[MAX_PATH] = "?";
  HMODULE owner = nullptr;
  if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                         static_cast<LPCSTR>(target), &owner)
      != FALSE) {
    GetModuleFileNameA(owner, module_name, MAX_PATH);
  }
  std::string message = "fefw: shader stage chains copied before vkCreateGraphicsPipelines (in ";
  message += module_name;
  message += ")";
  reshade::log::message(reshade::log::level::info, message.c_str());
}

static void Use(DWORD reason) {
  switch (reason) {
    case DLL_PROCESS_ATTACH:
      reshade::register_event<reshade::addon_event::init_device>(OnInitDevice);
      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_event<reshade::addon_event::init_device>(OnInitDevice);
      // The add-on unloads with the game: leave MinHook's state, but stop entering this module.
      if (internal::hooked_target != nullptr) {
        MH_DisableHook(internal::hooked_target);
        internal::hooked_target = nullptr;
      }
      break;
  }
}

}  // namespace fefw::stage_chain_copy
