#ifndef SRC_GAMES_FEFW_OBELISK_SHARED_H_
#define SRC_GAMES_FEFW_OBELISK_SHARED_H_

#define RENODX_TONE_MAP_TYPE_VANILLA  0.f
#define RENODX_TONE_MAP_TYPE_PSYCHOV  1.f
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
  float scene_color_space;
  float ui_color_space;
  float ui_brightness;
  float compare_vanilla;
};

#ifdef __cplusplus
static_assert(sizeof(ShaderInjectData) == 11u * sizeof(float));
#else
// Obelisk's Ryujinx-derived layouts use descriptor sets 0 to 3; the addon appends set 4.
layout(set = 4, binding = 0, scalar) uniform FefwShaderConstants {
  ShaderInjectData shader_injection;
} fefw_constants;
#define shader_injection fefw_constants.shader_injection
#define RENODX_COMPARE_VANILLA (shader_injection.compare_vanilla != 0.0)
#define RENODX_TONE_MAP_TYPE (RENODX_COMPARE_VANILLA ? RENODX_TONE_MAP_TYPE_VANILLA : shader_injection.tone_map_type)
#define RENODX_SCENE_COLOR_SPACE (RENODX_COMPARE_VANILLA ? RENODX_COLOR_SPACE_VANILLA : shader_injection.scene_color_space)
#define RENODX_UI_COLOR_SPACE (RENODX_COMPARE_VANILLA ? RENODX_COLOR_SPACE_VANILLA : shader_injection.ui_color_space)
#define RENODX_UI_BRIGHTNESS (RENODX_COMPARE_VANILLA ? 1.0 : shader_injection.ui_brightness)

// BT.709 -> BT.2020, GLSL column-major.
const mat3 FEFW_BT2020_FROM_BT709 = mat3(
    0.6274040, 0.0690970, 0.0163916,
    0.3292820, 0.9195400, 0.0880132,
    0.0433136, 0.0113612, 0.8955950);
#endif

#endif  // SRC_GAMES_FEFW_OBELISK_SHARED_H_
