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

## Build

`cmake --build --preset clang-x64-release --target fefw-obelisk` -> `build/release/renodx-fefw-obelisk.addon64`.
The `fefw-obelisk` workflow builds it on a push to the `fefw-obelisk` branch and uploads it as an artifact.

## Manual verification

1. Copy `renodx-fefw-obelisk.addon64` next to `ObeliskChamber.exe`; start the game, outdoor scene with sky.
2. ReShade log: `mods::shader attached`, no descriptor binding conflict.
3. With Lilium's HDR analysis: Tonemapper Vanilla + both color spaces Vanilla matches F10 (native) exactly;
   BT.709 scene color space drops the BT.2020 share of the sky towards 0 %.
4. F10 toggles between the mod and the native picture without a hitch.
