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
  float scene_gamut;
  float ui_color_space;
  float sdr_eotf_emulation;
  float ui_brightness;
  float compare_vanilla;
};

#ifdef __cplusplus
static_assert(sizeof(ShaderInjectData) == 14u * sizeof(float));
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
vec3 FefwEmulateGamma22(vec3 color) {
  vec3 magnitude = abs(color);
  vec3 encoded = mix(magnitude * 12.92, 1.055 * pow(magnitude, vec3(1.0 / 2.4)) - 0.055,
                     step(vec3(0.0031308), magnitude));
  return sign(color) * pow(encoded, vec3(2.2));
}
#endif

#endif  // SRC_GAMES_FEFW_OBELISK_SHARED_H_
