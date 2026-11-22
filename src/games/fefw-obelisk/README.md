# RenoDX – Fire Emblem: Fortune's Weave (Obelisk Chamber)

For Obelisk Chamber 0.3.1 (fefw-recomp fork, Vulkan) with `[hdr] mode = native` and an HDR10 display.
Needs ReShade with full add-on support, set up for `ObeliskChamber.exe` with the Vulkan API.

## What it changes

| Hash | Pass | Change |
|---|---|---|
| `0x07820DB2` | Scene tone map | PsychoV17 in place of the game's per-channel curve, anchored to the curve's own mid grey and peak; scene colors converted BT.709 -> BT.2020 |
| `0xE0A1145E` | UI composite | Exact BT.709 -> BT.2020 UI conversion in place of the game's wide-gamut matrix; UI brightness |

The final PQ encode (`0x250F769E`) is left as the game's. F10 switches every change off and on for comparison.
PsychoV17 comes from `../doom-tda/include/psychov_17.glsl`.

Obelisk Chamber chains one shared read-only `VkPipelineRobustnessCreateInfoEXT` to every shader stage
(`[nvn] robust_ubo`, on by default). ReShade appends to that chain when it rebuilds a pipeline with a replaced
shader, which crashes. `stage_chain_copy.hpp` hooks the `vkCreateGraphicsPipelines` the game calls and passes it
private copies of the stages and their chain structs, so `robust_ubo` stays on.

## Build

`cmake --build --preset clang-x64-release --target fefw-obelisk` -> `build/release/renodx-fefw-obelisk.addon64`.
The `fefw-obelisk` workflow builds it on a push to the `fefw-obelisk` branch and uploads it as an artifact.

## Manual verification

1. Copy `renodx-fefw-obelisk.addon64` next to `ObeliskChamber.exe`; start the game, outdoor scene with sky.
2. ReShade log: `mods::shader attached`, `fefw: shader stage chains copied before vkCreateGraphicsPipelines
   (in ...ReShade64.dll)`, no descriptor binding conflict; `ObeliskChamber.ini` without `robust_ubo = false`.
3. With Lilium's HDR analysis: Tonemapper Vanilla + both color spaces Vanilla matches F10 (native) exactly;
   BT.709 scene color space drops the BT.2020 share of the sky towards 0 %.
4. F10 toggles between the mod and the native picture without a hitch.
