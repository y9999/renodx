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

// CUSTOM: The original per-channel curve (power toe and linear middle blended by smoothstep, then an
// exponential shoulder toward `peak`), without its output scale. The game passes the same c[0] in both modes;
// HDR sets peak c[2].x to the display peak and scale c[2].y to 1, SDR sets 4/3 and 0.75 (read back with
// Show Curve Parameters). One unit is the same luminance in both, and SDR white is 4/3 units.
const float SDR_PEAK = 4.0 / 3.0;
const float SDR_SCALE = 0.75;

// CUSTOM: The game renders a slightly different scene for SDR output: the tone map inputs of both modes, captured
// at the same moment (Show Tone Map Input), differ by about this BT.2020 matrix (fitted with every hue weighted
// equally; SDR is 13 to 17% less saturated in warm colors). GLSL column-major.
const mat3 SDR_SCENE_FROM_HDR_SCENE = mat3(
    0.81696, 0.02310, 0.01241,
    0.08179, 0.88499, 0.04414,
    0.01453, 0.02194, 0.91681);

float ToneCurve(float x, float peak) {
    vec4 c0 = fp_c3_1._m0[0];  // slope, toe end, shoulder start fraction, toe power
    float toe_t = clamp(x / c0.y, 0.0, 1.0);
    float toe_blend = toe_t * toe_t * fma(toe_t, -2.0, 3.0);
    float shoulder_start = c0.y + (peak - c0.y) * c0.z / c0.x;
    float shoulder_scale = peak - fma(shoulder_start - c0.y, c0.x, c0.y);
    float in_shoulder = float(x >= shoulder_start);
    float toe = exp2(log2(max(x / c0.y, 1e-30)) * c0.w) * c0.y;
    float linear = fma(x - c0.y, c0.x, c0.y);
    float shoulder = peak - shoulder_scale * exp2((x - shoulder_start) * (-c0.x / shoulder_scale) * 1.44269504);
    return in_shoulder * shoulder + (toe_blend - in_shoulder) * linear + (1.0 - toe_blend) * toe;
}

// CUSTOM: 0 up to about 100 nits (half of SDR white), 1 from about 400 nits (twice SDR white): where the SDR
// picture stops being the reference and the HDR highlights begin. Saturated highlights such as fire are dim in
// luminance but clip in the SDR picture, so their brightest channel also counts, from SDR white (about 200 nits)
// to about 500 nits.
float HighlightWeight(vec3 color) {
    return max(smoothstep(0.5 * SDR_PEAK, 2.0 * SDR_PEAK, dot(color, vec3(0.2126, 0.7152, 0.0722))),
               smoothstep(SDR_PEAK, 2.5 * SDR_PEAK, max(color.r, max(color.g, color.b))));
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

    // CUSTOM: Scene tone mapping and gamut; the original curve above is kept as the Vanilla path. The scene is
    // BT.2020 (the SDR tone map converts it to BT.709); the steps below work in BT.709 like the SDR picture.
    vec3 input_view = FefwTonemapInputView(gl_FragCoord.xy, _42.xyz);
    if (input_view.x >= 0.0) {
        _32 = vec4(input_view, 1.0);
        return;
    }
    float parameter_bit = FefwCurveParameterBit(gl_FragCoord.xy, fp_c3_1._m0[0], fp_c3_1._m0[2]);
    if (parameter_bit >= 0.0) {
        _32 = vec4(vec3(parameter_bit), 1.0);
        return;
    }
    if (RENODX_COMPARE_VANILLA) {
        _32 = vec4(vanilla_output, _42.w);
        return;
    }
    vec3 vanilla = FEFW_BT709_FROM_BT2020 * vanilla_output;
    vec3 tonemapped = vanilla;
    if (RENODX_TONE_MAP_TYPE != RENODX_TONE_MAP_TYPE_VANILLA) {
        vec3 scene = FEFW_BT709_FROM_BT2020 * _42.xyz;
        // Where the original curve puts mid grey anchors PsychoV, so mid tones match Vanilla.
        float midgray_out = ToneCurve(0.18, fp_c3_1._m0[2].x) * shader_injection.tone_map_exposure;
        float peak = fp_c3_1._m0[2].x * shader_injection.tone_map_peak_scale;
        if (RENODX_TONE_MAP_TYPE == RENODX_TONE_MAP_TYPE_PSYCHOV17) {
            tonemapped = renodx::tonemap::psychov::psychotm_test17(
                scene, peak, midgray_out / 0.18,
                shader_injection.tone_map_highlights, shader_injection.tone_map_shadows,
                shader_injection.tone_map_contrast, shader_injection.tone_map_saturation,
                1.0, 100.0, 1.0, 1.0, 0, 1.0, vec3(0.18), vec3(0.18), 1.0, 1, 1.0);
        } else {
            // Cone response from the original curve's log slope over half a stop around mid grey.
            float cone = 1.0;
            if (shader_injection.tone_map_vanilla_contrast != 0.0) {
                cone = clamp(2.0 * log2(ToneCurve(0.18 * 1.18920712, fp_c3_1._m0[2].x)
                                        / ToneCurve(0.18 / 1.18920712, fp_c3_1._m0[2].x)),
                             0.5, 2.5);
            }
            // Fitted to the BT.2020 display gamut; colors outside BT.709 come back as negative components.
            // PsychoV35 needs its output anchor below the peak.
            tonemapped = renodx::tonemap::psychov::psychotm_test35(
                scene, peak, 1.0,
                shader_injection.tone_map_highlights, shader_injection.tone_map_shadows,
                shader_injection.tone_map_contrast, shader_injection.tone_map_saturation,
                1.0, 100.0, 1.0, 1.0, 0, cone, vec3(0.18), vec3(min(midgray_out, 0.95 * peak)), 1.0, 1, 1.0, 1.0);
        }
        tonemapped *= fp_c3_1._m0[2].y;
        // Vanilla+: the original curve where the SDR picture is the reference, PsychoV35's brightness in the
        // highlights with the original curve's hues and saturation, which keep fire orange instead of whitening it.
        if (RENODX_TONE_MAP_TYPE == RENODX_TONE_MAP_TYPE_VANILLA_PLUS) {
            float highlight = HighlightWeight(vanilla);
            tonemapped = mix(vanilla, tonemapped, highlight);
            float vanilla_luminance = dot(vanilla, vec3(0.2126, 0.7152, 0.0722));
            if (vanilla_luminance > 0.0) {
                vec3 reference = vanilla * (dot(tonemapped, vec3(0.2126, 0.7152, 0.0722)) / vanilla_luminance);
                tonemapped = renodx::color::correct::HueOKLab(tonemapped, reference, highlight);
                tonemapped = renodx::color::correct::ChrominanceOKLab(tonemapped, reference, highlight);
            }
        }
    }
    // Where the SDR picture is the reference: its hues and saturation (the SDR scene through the SDR tone map: the
    // curve with the SDR peak, then BT.709 without negative channels), then its gamut. The highlights keep their
    // colors, and Warm Tones can keep the HDR scene's colors for reds to yellows.
    vec3 lab = renodx::color::oklab::from::BT709(tonemapped);
    float hue = degrees(atan(lab.z, lab.y));
    float warm = smoothstep(-15.0, 0.0, hue) * (1.0 - smoothstep(110.0, 125.0, hue));
    float sdr_weight = (1.0 - HighlightWeight(tonemapped)) * mix(1.0, RENODX_WARM_TONES, warm);
    if (RENODX_SDR_HUE_CHROMINANCE > 0.0) {
        vec3 sdr_scene = max(SDR_SCENE_FROM_HDR_SCENE * _42.xyz, vec3(0.0));
        vec3 sdr_reference = clamp(
            FEFW_BT709_FROM_BT2020
                * vec3(ToneCurve(sdr_scene.x, SDR_PEAK), ToneCurve(sdr_scene.y, SDR_PEAK),
                       ToneCurve(sdr_scene.z, SDR_PEAK)),
            0.0, SDR_PEAK);
        // Brought to the result's luminance: the SDR picture's saturation, not its lower level.
        float reference_luminance = dot(sdr_reference, vec3(0.2126, 0.7152, 0.0722));
        if (reference_luminance > 0.0) {
            sdr_reference *= dot(tonemapped, vec3(0.2126, 0.7152, 0.0722)) / reference_luminance;
        }
        float strength = RENODX_SDR_HUE_CHROMINANCE * sdr_weight;
        tonemapped = renodx::color::correct::HueOKLab(tonemapped, sdr_reference, strength);
        tonemapped = renodx::color::correct::ChrominanceOKLab(tonemapped, sdr_reference, strength);
        // The SDR scene also draws warm hues toward gold, which the matrix leaves out: oranges toward yellow, yellows
        // toward orange (tone map inputs of both modes: +3.5 to +5.7 degrees at OKLab hues 50 to 70, -4 to -10 at
        // 80 to 100; skin of two scenes +2.8 to +4.5). A pull toward 75 degrees between 48 and 110, 0.25 from the
        // orange side and 0.4 from the yellow side.
        lab = renodx::color::oklab::from::BT709(tonemapped);
        hue = degrees(atan(lab.z, lab.y));
        float gold = smoothstep(48.0, 56.0, hue) * (1.0 - smoothstep(98.0, 110.0, hue));
        float angle = radians(-(hue < 75.0 ? 0.25 : 0.4) * (hue - 75.0) * gold * strength);
        lab.yz = mat2(cos(angle), sin(angle), -sin(angle), cos(angle)) * lab.yz;
        tonemapped = renodx::color::bt709::from::OkLab(lab);
    }
    if (RENODX_SCENE_GAMUT_SDR) {
        tonemapped = mix(tonemapped, max(tonemapped, vec3(0.0)), sdr_weight);
    }
    if (RENODX_SDR_EOTF_EMULATION) {
        tonemapped = FefwEmulateGamma22(tonemapped * SDR_SCALE) / SDR_SCALE;  // relative to SDR white
    }
    // R11G11B10F cannot hold negative values.
    _32 = vec4(max(FEFW_BT2020_FROM_BT709 * tonemapped, vec3(0.0)), _42.w);
}
