#ifndef SRC_GAMES_FEFW_OBELISK_SHARED_H_
#define SRC_GAMES_FEFW_OBELISK_SHARED_H_

#define RENODX_TONE_MAP_TYPE_VANILLA   0.f
#define RENODX_TONE_MAP_TYPE_PSYCHOV17 1.f
#define RENODX_TONE_MAP_TYPE_PSYCHOV35 2.f
#define RENODX_TONE_MAP_TYPE_VANILLA_PLUS 3.f
#define RENODX_COLOR_SPACE_VANILLA    0.f
#define RENODX_COLOR_SPACE_BT709      1.f

struct ShaderInjectData {
  float tone_map_type;
  float tone_map_peak_scale;
  float tone_map_exposure;
  float tone_map_highlights;
  float tone_map_shadows;
  float tone_map_contrast;
  float tone_map_saturation;
  float tone_map_vanilla_contrast;
  float hue_clip_emulation;
  float warm_tones;
  float scene_gamut;
  float ui_color_space;
  float sdr_eotf_emulation;
  float ui_brightness;
  float compare_vanilla;
  float show_curve_parameters;
  float show_tonemap_input;
};

#ifdef __cplusplus
static_assert(sizeof(ShaderInjectData) == 17u * sizeof(float));
#else
// Obelisk's Ryujinx-derived layouts use descriptor sets 0 to 3; the addon appends set 4.
layout(set = 4, binding = 0, scalar) uniform FefwShaderConstants {
  ShaderInjectData shader_injection;
} fefw_constants;
#define shader_injection fefw_constants.shader_injection
#define RENODX_COMPARE_VANILLA (shader_injection.compare_vanilla != 0.0)
#define RENODX_TONE_MAP_TYPE (RENODX_COMPARE_VANILLA ? RENODX_TONE_MAP_TYPE_VANILLA : shader_injection.tone_map_type)
#define RENODX_UI_COLOR_SPACE (RENODX_COMPARE_VANILLA ? RENODX_COLOR_SPACE_VANILLA : shader_injection.ui_color_space)
#define RENODX_UI_BRIGHTNESS (RENODX_COMPARE_VANILLA ? 1.0 : shader_injection.ui_brightness)
#define RENODX_SDR_HUE_CHROMINANCE shader_injection.hue_clip_emulation
#define RENODX_WARM_TONES shader_injection.warm_tones
#define RENODX_SCENE_GAMUT_SDR (shader_injection.scene_gamut != 0.0)
#define RENODX_SDR_EOTF_EMULATION (!RENODX_COMPARE_VANILLA && shader_injection.sdr_eotf_emulation != 0.0)

// BT.709 <-> BT.2020, GLSL column-major. The scene is rendered in BT.2020: the SDR tone map converts it to
// BT.709 and drops negative channels, the HDR output sends it to the display as is.
const mat3 FEFW_BT2020_FROM_BT709 = mat3(
    0.6274040, 0.0690970, 0.0163916,
    0.3292820, 0.9195400, 0.0880132,
    0.0433136, 0.0113612, 0.8955950);
const mat3 FEFW_BT709_FROM_BT2020 = mat3(
    1.6604910, -0.1245505, -0.0181508,
    -0.5876411, 1.1328999, -0.1005789,
    -0.0728499, -0.0083494, 1.1187297);

// The game encodes SDR with the sRGB curve and SDR displays decode it with gamma 2.2: in linear BT.709,
// relative to SDR white, this is the SDR picture as it was seen. Signs are kept for wide-gamut colors.
// Diagnostic: the tone map's curve parameters (c[0].xyzw, c[2].xyzw) written into the picture as bits, so a
// capture holds their exact values. 12-pixel blocks from (64, 64): one row per value, most significant bit
// first, then a white and a black calibration row. Returns -1 outside the block area, else 0 or 1.
float FefwCurveParameterBit(vec2 position, vec4 c0, vec4 c2) {
  ivec2 block = ivec2(floor((position - 64.0) / 12.0));
  if (shader_injection.show_curve_parameters == 0.0 || any(lessThan(block, ivec2(0)))
      || block.x >= 32 || block.y >= 10) {
    return -1.0;
  }
  if (block.y >= 8) return float(block.y == 8);
  float value = block.y < 4 ? c0[block.y] : c2[block.y - 4];
  return float((floatBitsToUint(value) >> uint(31 - block.x)) & 1u);
}

// Diagnostic: the tone map's input (the BT.2020 scene, before any curve) as x / (1 + x) per channel, so it
// survives the SDR output's [0, 1] range and decodes back as y / (1 - y). A white square at (16..48, 16..48)
// gives the output scale. Returns -1 when the diagnostic is off.
vec3 FefwTonemapInputView(vec2 position, vec3 scene) {
  if (shader_injection.show_tonemap_input == 0.0) return vec3(-1.0);
  if (all(lessThan(abs(position - 32.0), vec2(16.0)))) return vec3(1.0);
  vec3 x = max(scene, vec3(0.0));
  return x / (1.0 + x);
}

vec3 FefwEmulateGamma22(vec3 color) {
  vec3 magnitude = abs(color);
  vec3 encoded = mix(magnitude * 12.92, 1.055 * pow(magnitude, vec3(1.0 / 2.4)) - 0.055,
                     step(vec3(0.0031308), magnitude));
  return sign(color) * pow(encoded, vec3(2.2));
}
#endif

#endif  // SRC_GAMES_FEFW_OBELISK_SHARED_H_
