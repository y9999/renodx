/*
 * Copyright (C) 2026 y9999
 * SPDX-License-Identifier: MIT
 */

// Fire Emblem: Fortune's Weave on the Obelisk Chamber recompilation (Vulkan), with the game's native
// HDR output ([hdr] mode = native). The game tone maps its scene per channel with its shoulder at the
// display peak, writes the result unchanged into an HDR10 swapchain as BT.2020, and composites its UI
// with a wide-gamut matrix: the scene keeps the full strength of its SDR grade up to the peak.

#define ImTextureID ImU64

#include <deps/imgui/imgui.h>
#include <embed/shaders.h>
#include <include/reshade.hpp>

#include <cstdint>
#include <span>

#include "../../mods/shader.hpp"
#include "../../utils/settings.hpp"
#include "./shared.h"
#include "./stage_chain_copy.hpp"

namespace {

bool addon_registered = false;
ShaderInjectData shader_injection = {};

// Win32 virtual-key code of F10; Obelisk Chamber uses F1 and F2 for its own overlays.
constexpr uint32_t COMPARE_VANILLA_KEY = 0x79u;

renodx::mods::shader::CustomShaders custom_shaders = {
    CustomShaderEntry(0x07820DB2),  // Scene tone map (per-channel toe, linear, exponential shoulder)
    CustomShaderEntry(0xE0A1145E),  // UI composite onto the HDR scene
};

bool IsPsychoVEnabled() {
  return shader_injection.tone_map_type != RENODX_TONE_MAP_TYPE_VANILLA;
}

renodx::utils::settings::Settings settings = {
    new renodx::utils::settings::Setting{
        .key = "ToneMapType",
        .binding = &shader_injection.tone_map_type,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 2.f,
        .label = "Tonemapper",
        .section = "Tone Mapping",
        .tooltip = "Vanilla keeps the game's per-channel curve. PsychoV keeps hues and maps highlights to the peak;"
                   " PsychoV35 is the current version and also fits colors to the BT.2020 display gamut.",
        .labels = {"Vanilla", "PsychoV17", "PsychoV35"},
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapPeakScale",
        .binding = &shader_injection.tone_map_peak_scale,
        .default_value = 100.f,
        .label = "Peak Brightness",
        .section = "Tone Mapping",
        .tooltip = "Relative to Peak brightness in Obelisk Chamber's F1 menu.",
        .min = 25.f,
        .max = 200.f,
        .format = "%.0f%%",
        .is_enabled = &IsPsychoVEnabled,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapExposure",
        .binding = &shader_injection.tone_map_exposure,
        .default_value = 1.f,
        .label = "Exposure",
        .section = "Tone Mapping",
        .max = 2.f,
        .format = "%.2fx",
        .is_enabled = &IsPsychoVEnabled,
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapHighlights",
        .binding = &shader_injection.tone_map_highlights,
        .default_value = 50.f,
        .label = "Highlights",
        .section = "Tone Mapping",
        .is_enabled = &IsPsychoVEnabled,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapShadows",
        .binding = &shader_injection.tone_map_shadows,
        .default_value = 50.f,
        .label = "Shadows",
        .section = "Tone Mapping",
        .is_enabled = &IsPsychoVEnabled,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapContrast",
        .binding = &shader_injection.tone_map_contrast,
        .default_value = 50.f,
        .label = "Contrast",
        .section = "Tone Mapping",
        .is_enabled = &IsPsychoVEnabled,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapSaturation",
        .binding = &shader_injection.tone_map_saturation,
        .default_value = 50.f,
        .label = "Saturation",
        .section = "Tone Mapping",
        .is_enabled = &IsPsychoVEnabled,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapVanillaContrast",
        .binding = &shader_injection.tone_map_vanilla_contrast,
        .value_type = renodx::utils::settings::SettingValueType::BOOLEAN,
        .default_value = 1.f,
        .label = "Vanilla Contrast",
        .section = "Tone Mapping",
        .tooltip = "PsychoV35 takes the contrast of the game's curve around mid grey instead of its own.",
        .is_enabled = []() { return shader_injection.tone_map_type == RENODX_TONE_MAP_TYPE_PSYCHOV35; },
    },
    new renodx::utils::settings::Setting{
        .key = "HueClipEmulation",
        .binding = &shader_injection.hue_clip_emulation,
        .default_value = 100.f,
        .label = "Hue Clip Emulation",
        .section = "Tone Mapping",
        .tooltip = "Takes the hues of the SDR picture, where the game's curve clips each channel on its own.",
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "SceneColorSpace",
        .binding = &shader_injection.scene_color_space,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 1.f,
        .label = "Scene Color Space",
        .section = "Color",
        .tooltip = "Vanilla sends the scene's colors to the display as BT.2020 unchanged."
                   " BT.709 converts them, as in the SDR picture.",
        .labels = {"Vanilla", "BT.709"},
    },
    new renodx::utils::settings::Setting{
        .key = "UIColorSpace",
        .binding = &shader_injection.ui_color_space,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 1.f,
        .label = "UI Color Space",
        .section = "Color",
        .tooltip = "Vanilla uses the game's wide-gamut UI matrix. BT.709 converts the UI exactly.",
        .labels = {"Vanilla", "BT.709"},
    },
    new renodx::utils::settings::Setting{
        .key = "SDREOTFEmulation",
        .binding = &shader_injection.sdr_eotf_emulation,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 1.f,
        .label = "SDR EOTF Emulation",
        .section = "Color",
        .tooltip = "2.2 shows shadows and dark colors as the SDR picture looks on a gamma 2.2 display."
                   " Off keeps the game's sRGB-relative values. Applies to the UI with UI Color Space BT.709.",
        .labels = {"Off", "2.2"},
    },
    new renodx::utils::settings::Setting{
        .key = "UIBrightness",
        .binding = &shader_injection.ui_brightness,
        .default_value = 100.f,
        .label = "UI Brightness",
        .section = "Color",
        .tooltip = "Relative to Paper white in Obelisk Chamber's F1 menu.",
        .min = 25.f,
        .max = 200.f,
        .format = "%.0f%%",
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::TEXT,
        .label = "F10: switch between this mod and the game's native HDR, for comparison.",
        .section = "Options",
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::BUTTON,
        .label = "Reset All",
        .section = "Options",
        .on_change = []() { renodx::utils::settings::ResetSettings(); },
    },
};

void OnPresetOff() {
  renodx::utils::settings::UpdateSettings({
      {"ToneMapType", 0.f},
      {"ToneMapPeakScale", 100.f},
      {"ToneMapExposure", 1.f},
      {"ToneMapHighlights", 50.f},
      {"ToneMapShadows", 50.f},
      {"ToneMapContrast", 50.f},
      {"ToneMapSaturation", 50.f},
      {"ToneMapVanillaContrast", 1.f},
      {"HueClipEmulation", 0.f},
      {"SceneColorSpace", 0.f},
      {"UIColorSpace", 0.f},
      {"SDREOTFEmulation", 0.f},
      {"UIBrightness", 100.f},
  });
}

// The comparison toggle is not a setting: it is never saved, so every start shows the mod.
void OnReShadePresent(reshade::api::effect_runtime* runtime) {
  if (runtime->is_key_pressed(COMPARE_VANILLA_KEY)) {
    shader_injection.compare_vanilla = (shader_injection.compare_vanilla == 0.f ? 1.f : 0.f);
  }
}

}  // namespace

extern "C" __declspec(dllexport) constexpr const char* NAME = "RenoDX";
extern "C" __declspec(dllexport) constexpr const char* DESCRIPTION =
    "RenoDX for Fire Emblem: Fortune's Weave (Obelisk Chamber)";

BOOL APIENTRY DllMain(HMODULE h_module, DWORD reason, [[maybe_unused]] LPVOID reserved) {
  switch (reason) {
    case DLL_PROCESS_ATTACH: {
      if (!reshade::register_addon(h_module)) return FALSE;
      addon_registered = true;
      // Substitute bytecode when Obelisk Chamber builds its pipelines; it prebuilds them at start.
      renodx::mods::shader::manual_shader_scheduling = true;
      for (auto& [hash, shader] : custom_shaders) {
        renodx::utils::shader::QueueCompileTimeReplacement(hash, shader.code);
        shader.views.push_back({
            .type = reshade::api::descriptor_type::constant_buffer,
            .slot = 0u,
            .space = 4u,
            .get_constants = []() -> std::span<const float> {
              return {reinterpret_cast<const float*>(&shader_injection), sizeof(shader_injection) / sizeof(float)};
            },
        });
      }
      reshade::register_event<reshade::addon_event::reshade_present>(OnReShadePresent);
      fefw::stage_chain_copy::Use(reason);
      renodx::utils::settings::Use(reason, &settings, &OnPresetOff);
      renodx::mods::shader::Use(reason, custom_shaders);
      break;
    }
    case DLL_PROCESS_DETACH:
      if (addon_registered) {
        renodx::mods::shader::Use(reason, custom_shaders);
        renodx::utils::settings::Use(reason, &settings, &OnPresetOff);
        fefw::stage_chain_copy::Use(reason);
        reshade::unregister_event<reshade::addon_event::reshade_present>(OnReShadePresent);
        reshade::unregister_addon(h_module);
      }
      break;
  }
  return TRUE;
}
