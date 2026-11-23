#version 450
#extension GL_EXT_scalar_block_layout : require

// Scene tone map (draw before sharpening and the UI composite). Decompiled with SPIRV-Cross from the
// SPIR-V Obelisk Chamber 0.3.1 hands to Vulkan; compiled by Slang so the HLSL PsychoV35 can be included.
#include "./shared.h"
#include "../../shaders/tonemap/psychov/test17.hlsl"
#include "../../shaders/tonemap/psychov/test35.hlsl"
#include "../../shaders/colorcorrect.hlsl"

layout(set = 0, binding = 0, std140) uniform support_buffer
{
    uint _m0;
    uint _m1[8];
    vec4 _m2;
    vec4 _m3;
    int _m4;
    float _m5[73];
    ivec4 _m6;
    int _m7;
} support_buffer_1;

layout(set = 0, binding = 22, std140) uniform fp_c3
{
    vec4 _m0[4096];
} fp_c3_1;

layout(set = 2, binding = 128) uniform sampler2D fp_t_tcb_8;

layout(location = 0) in vec4 _29;
layout(location = 0) out vec4 _32;

// CUSTOM: The original per-channel curve for one value, without its output scale c[2].y:
// power toe and linear middle blended by smoothstep, then the exponential shoulder from shoulder_start.
float VanillaCurve(float x, float inverse_toe_end, float shoulder_scale, float shoulder_start, float shoulder_rate) {
    float toe_t = clamp(x * inverse_toe_end, 0.0, 1.0);
    float toe_blend = toe_t * toe_t * fma(toe_t, -2.0, 3.0);
    float in_shoulder = float(x >= shoulder_start);
    float toe = exp2(log2(x * inverse_toe_end) * fp_c3_1._m0[0].w) * fp_c3_1._m0[0].y;
    float linear = fma(x - fp_c3_1._m0[0].y, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    float shoulder = fma(-shoulder_scale, exp2((x - shoulder_start) * shoulder_rate), fp_c3_1._m0[2].x);
    return in_shoulder * shoulder + (toe_blend - in_shoulder) * linear + (1.0 - toe_blend) * toe;
}

void main()
{
    precise float _96 = 1.0 / gl_FragCoord.w;
    float _39 = _96;
    precise float _104 = _29.x * gl_FragCoord.w;
    precise float _105 = _39 * _104;
    precise float _112 = _29.y * gl_FragCoord.w;
    precise float _113 = _39 * _112;
    vec4 _42 = texture(fp_t_tcb_8, vec2(_105, _113)).xyzw;
    float _44 = _42.x;
    float _46 = _42.y;
    float _48 = _42.z;
    precise float _127 = 1.0 / fp_c3_1._m0[0].y;
    float _50 = _127;
    precise float _134 = (-fp_c3_1._m0[0].y) + fp_c3_1._m0[2].x;
    precise float _137 = _134 * fp_c3_1._m0[0].z;
    precise float _140 = 1.0 / fp_c3_1._m0[0].x;
    precise float _141 = _137 * _140;
    float _52 = _141;
    precise float _152 = (-fma(_52, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y)) + fp_c3_1._m0[2].x;
    float _54 = _152;
    precise float _155 = _44 * _50;
    float _56 = _155;
    precise float _158 = _46 * _50;
    float _58 = _158;
    precise float _161 = _48 * _50;
    float _60 = _161;
    precise float _165 = _52 + fp_c3_1._m0[0].y;
    float _62 = _165;
    precise float _168 = 0.0 + _56;
    float _64 = clamp(_168, 0.0, 1.0);
    float _66 = float(((_44 >= _62) || isnan(_44)) || isnan(_62));
    precise float _185 = fp_c3_1._m0[2].x * fp_c3_1._m0[0].x;
    precise float _187 = 1.0 / _54;
    precise float _188 = _185 * _187;
    precise float _191 = 1.0 / fp_c3_1._m0[2].x;
    precise float _193 = _188 * (-_191);
    float _68 = _193;
    precise float _196 = _68 * 1.44269502162933349609375;
    float _70 = _196;
    float _72 = float(((_46 >= _62) || isnan(_46)) || isnan(_62));
    precise float _208 = 0.0 + _58;
    float _74 = clamp(_208, 0.0, 1.0);
    float _76 = float(((_48 >= _62) || isnan(_48)) || isnan(_62));
    precise float _221 = 0.0 + _60;
    float _78 = clamp(_221, 0.0, 1.0);
    precise float _225 = _64 * _64;
    float _80 = _225;
    float _82 = fma(_64, -2.0, 3.0);
    float _84 = fma(_74, -2.0, 3.0);
    precise float _234 = _74 * _74;
    float _86 = _234;
    float _88 = fma(_78, -2.0, 3.0);
    precise float _239 = _78 * _78;
    float _90 = _239;
    precise float _248 = _44 + (-_62);
    precise float _250 = _248 * _70;
    precise float _264 = log2(abs(_56)) * fp_c3_1._m0[0].w;
    precise float _268 = exp2(_264) * fp_c3_1._m0[0].y;
    precise float _278 = _44 + (-fp_c3_1._m0[0].y);
    precise float _284 = fma(_82, _80, -_66) * fma(_278, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    precise float _289 = fma(_66, fma(-_54, exp2(_250), fp_c3_1._m0[2].x), fma(fma(_82, -_80, 1.0), _268, _284)) * fp_c3_1._m0[2].y;
    vec3 vanilla_output;
    vanilla_output.x = _289;
    precise float _297 = _46 + (-_62);
    precise float _299 = _297 * _70;
    precise float _313 = log2(abs(_58)) * fp_c3_1._m0[0].w;
    precise float _317 = exp2(_313) * fp_c3_1._m0[0].y;
    precise float _327 = _46 + (-fp_c3_1._m0[0].y);
    precise float _333 = fma(_84, _86, -_72) * fma(_327, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    precise float _338 = fma(_72, fma(-_54, exp2(_299), fp_c3_1._m0[2].x), fma(fma(_84, -_86, 1.0), _317, _333)) * fp_c3_1._m0[2].y;
    vanilla_output.y = _338;
    precise float _346 = _48 + (-_62);
    precise float _348 = _346 * _68;
    precise float _349 = _348 * 1.44269502162933349609375;
    precise float _363 = log2(abs(_60)) * fp_c3_1._m0[0].w;
    precise float _367 = exp2(_363) * fp_c3_1._m0[0].y;
    precise float _377 = _48 + (-fp_c3_1._m0[0].y);
    precise float _383 = fma(_88, _90, -_76) * fma(_377, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    precise float _388 = fma(_76, fma(-_54, exp2(_349), fp_c3_1._m0[2].x), fma(fma(_88, -_90, 1.0), _367, _383)) * fp_c3_1._m0[2].y;
    vanilla_output.z = _388;

    // CUSTOM: Scene tone mapping and color space; the original curve above is kept as the Vanilla path.
    vec3 tonemapped = vanilla_output;
    if (RENODX_TONE_MAP_TYPE != RENODX_TONE_MAP_TYPE_VANILLA) {
        // Where the original curve puts mid grey anchors PsychoV, so mid tones match Vanilla.
        float midgray_out = VanillaCurve(0.18, _50, _54, _62, _70) * shader_injection.tone_map_exposure;
        float peak = fp_c3_1._m0[2].x * shader_injection.tone_map_peak_scale;
        if (RENODX_TONE_MAP_TYPE == RENODX_TONE_MAP_TYPE_PSYCHOV17) {
            tonemapped = renodx::tonemap::psychov::psychotm_test17(
                _42.xyz, peak, midgray_out / 0.18,
                shader_injection.tone_map_highlights, shader_injection.tone_map_shadows,
                shader_injection.tone_map_contrast, shader_injection.tone_map_saturation,
                1.0, 100.0, 1.0, 1.0, 0, 1.0, vec3(0.18), vec3(0.18), 1.0, 1, 1.0);
        } else {
            // Cone response from the original curve's log slope over half a stop around mid grey.
            float cone = 1.0;
            if (shader_injection.tone_map_vanilla_contrast != 0.0) {
                cone = clamp(2.0 * log2(VanillaCurve(0.18 * 1.18920712, _50, _54, _62, _70)
                                        / VanillaCurve(0.18 / 1.18920712, _50, _54, _62, _70)),
                             0.5, 2.5);
            }
            // Fitted to the BT.2020 display gamut; colors outside BT.709 come back as negative components.
            // PsychoV35 needs its output anchor below the peak.
            tonemapped = renodx::tonemap::psychov::psychotm_test35(
                _42.xyz, peak, 1.0,
                shader_injection.tone_map_highlights, shader_injection.tone_map_shadows,
                shader_injection.tone_map_contrast, shader_injection.tone_map_saturation,
                1.0, 100.0, 1.0, 1.0, 0, cone, vec3(0.18), vec3(min(midgray_out, 0.95 * peak)), 1.0, 1, 1.0, 1.0);
        }
        tonemapped *= fp_c3_1._m0[2].y;
    }
    if (RENODX_HUE_CLIP_EMULATION > 0.0) {
        // Hues of the SDR picture: the original curve per channel, without negative channels and clipped at
        // SDR white (1.0 here), as the SDR output stores them.
        vec3 sdr_reference = clamp(
            vec3(VanillaCurve(max(_44, 0.0), _50, _54, _62, _70),
                 VanillaCurve(max(_46, 0.0), _50, _54, _62, _70),
                 VanillaCurve(max(_48, 0.0), _50, _54, _62, _70))
                * fp_c3_1._m0[2].y,
            0.0, 1.0);
        tonemapped = renodx::color::correct::HueOKLab(tonemapped, sdr_reference, RENODX_HUE_CLIP_EMULATION);
    }
    if (RENODX_SDR_EOTF_EMULATION) {
        tonemapped = FefwEmulateGamma22(tonemapped);
    }
    if (RENODX_SCENE_COLOR_SPACE == RENODX_COLOR_SPACE_BT709) {
        tonemapped = FEFW_BT2020_FROM_BT709 * tonemapped;
    }
    // R11G11B10F cannot hold negative values.
    _32 = vec4(max(tonemapped, vec3(0.0)), _42.w);
}
