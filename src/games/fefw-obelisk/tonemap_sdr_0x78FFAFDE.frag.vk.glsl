#version 450
#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_scalar_block_layout : require

// SDR scene tone map (the SDR output's variant of 0x07820DB2: same curve, then BT.2020 -> BT.709 with negative
// channels dropped). Replaced only for the diagnostics; otherwise unchanged.
#include "./shared.h"

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

void main()
{
    precise float _108 = 1.0 / gl_FragCoord.w;
    float _39 = _108;
    precise float _116 = _29.x * gl_FragCoord.w;
    precise float _117 = _39 * _116;
    precise float _124 = _29.y * gl_FragCoord.w;
    precise float _125 = _39 * _124;
    vec4 _42 = texture(fp_t_tcb_8, vec2(_117, _125)).xyzw;
    float _44 = _42.x;
    float _46 = _42.y;
    float _48 = _42.z;
    precise float _139 = 1.0 / fp_c3_1._m0[0].y;
    float _50 = _139;
    precise float _146 = (-fp_c3_1._m0[0].y) + fp_c3_1._m0[2].x;
    precise float _149 = _146 * fp_c3_1._m0[0].z;
    precise float _152 = 1.0 / fp_c3_1._m0[0].x;
    precise float _153 = _149 * _152;
    float _52 = _153;
    precise float _164 = (-fma(_52, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y)) + fp_c3_1._m0[2].x;
    float _54 = _164;
    precise float _169 = fp_c3_1._m0[2].x * fp_c3_1._m0[0].x;
    precise float _171 = 1.0 / _54;
    precise float _172 = _169 * _171;
    precise float _175 = 1.0 / fp_c3_1._m0[2].x;
    precise float _177 = _172 * (-_175);
    float _56 = _177;
    precise float _180 = _56 * 1.44269502162933349609375;
    float _58 = _180;
    precise float _183 = _46 * _50;
    float _60 = _183;
    precise float _186 = _44 * _50;
    float _62 = _186;
    precise float _189 = _48 * _50;
    float _64 = _189;
    precise float _193 = _52 + fp_c3_1._m0[0].y;
    float _66 = _193;
    float _68 = float(((_44 >= _66) || isnan(_44)) || isnan(_66));
    float _70 = float(((_46 >= _66) || isnan(_46)) || isnan(_66));
    float _72 = float(((_48 >= _66) || isnan(_48)) || isnan(_66));
    precise float _227 = 0.0 + _60;
    float _74 = clamp(_227, 0.0, 1.0);
    precise float _230 = 0.0 + _62;
    float _76 = clamp(_230, 0.0, 1.0);
    float _78 = fma(_74, -2.0, 3.0);
    precise float _238 = _76 * _76;
    float _80 = _238;
    precise float _240 = 0.0 + _64;
    float _82 = clamp(_240, 0.0, 1.0);
    float _84 = fma(_82, -2.0, 3.0);
    float _86 = fma(_76, -2.0, 3.0);
    precise float _248 = _74 * _74;
    float _88 = _248;
    precise float _251 = _82 * _82;
    float _90 = _251;
    precise float _258 = _44 + (-_66);
    precise float _260 = _258 * _58;
    precise float _274 = log2(abs(_62)) * fp_c3_1._m0[0].w;
    precise float _278 = exp2(_274) * fp_c3_1._m0[0].y;
    precise float _288 = _44 + (-fp_c3_1._m0[0].y);
    precise float _294 = fma(_86, _80, -_68) * fma(_288, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    precise float _299 = fma(_68, fma(-_54, exp2(_260), fp_c3_1._m0[2].x), fma(fma(_86, -_80, 1.0), _278, _294)) * fp_c3_1._m0[2].y;
    float _92 = _299;
    precise float _306 = _46 + (-_66);
    precise float _308 = _306 * _58;
    precise float _322 = log2(abs(_60)) * fp_c3_1._m0[0].w;
    precise float _326 = exp2(_322) * fp_c3_1._m0[0].y;
    precise float _336 = _46 + (-fp_c3_1._m0[0].y);
    precise float _342 = fma(_78, _88, -_70) * fma(_336, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    precise float _347 = fma(_70, fma(-_54, exp2(_308), fp_c3_1._m0[2].x), fma(fma(_78, -_88, 1.0), _326, _342)) * fp_c3_1._m0[2].y;
    float _94 = _347;
    precise float _354 = _48 + (-_66);
    precise float _356 = _354 * _56;
    precise float _357 = _356 * 1.44269502162933349609375;
    precise float _371 = log2(abs(_64)) * fp_c3_1._m0[0].w;
    precise float _375 = exp2(_371) * fp_c3_1._m0[0].y;
    precise float _385 = _48 + (-fp_c3_1._m0[0].y);
    precise float _391 = fma(_84, _90, -_72) * fma(_385, fp_c3_1._m0[0].x, fp_c3_1._m0[0].y);
    precise float _396 = fma(_72, fma(-_54, exp2(_357), fp_c3_1._m0[2].x), fma(fma(_84, -_90, 1.0), _375, _391)) * fp_c3_1._m0[2].y;
    float _96 = _396;
    precise float _403 = _94 * (-0.5876390933990478515625);
    float _98 = fma(_96, -0.072851501405239105224609375, fma(_92, 1.6604902744293212890625, _403));
    precise float _412 = _94 * 1.1328999996185302734375;
    float _100 = fma(_96, -0.008347899653017520904541015625, fma(_92, -0.124549902975559234619140625, _412));
    precise float _421 = _94 * (-0.100578702986240386962890625);
    float _102 = fma(_96, 1.1187298297882080078125, fma(_92, -0.0181511007249355316162109375, _421));
    _32.x = intBitsToFloat((!true) ? floatBitsToInt(min(0.0, _98)) : floatBitsToInt(max(0.0, _98)));
    _32.y = intBitsToFloat((!true) ? floatBitsToInt(min(0.0, _100)) : floatBitsToInt(max(0.0, _100)));
    _32.z = intBitsToFloat((!true) ? floatBitsToInt(min(0.0, _102)) : floatBitsToInt(max(0.0, _102)));
    _32.w = _42.w;
    // CUSTOM: Diagnostics (tone map input, curve parameters).
    vec3 input_view = FefwTonemapInputView(gl_FragCoord.xy, _42.xyz);
    if (input_view.x >= 0.0) {
        _32 = vec4(input_view, 1.0);
        return;
    }
    float parameter_bit = FefwCurveParameterBit(gl_FragCoord.xy, fp_c3_1._m0[0], fp_c3_1._m0[2]);
    if (parameter_bit >= 0.0) {
        _32 = vec4(vec3(parameter_bit), 1.0);
    }
}
