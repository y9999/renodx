#version 450
#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_scalar_block_layout : require

// UI composite onto the HDR scene (draw right before the PQ encode). The game converts the sRGB-decoded UI
// with its own wide-gamut matrix; BT.709 mode converts it to BT.2020 exactly instead.
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
    precise float _54 = 1.0 / gl_FragCoord.w;
    float _39 = _54;
    precise float _62 = _29.x * gl_FragCoord.w;
    precise float _63 = _39 * _62;
    precise float _70 = _29.y * gl_FragCoord.w;
    precise float _71 = _39 * _70;
    vec4 _42 = texture(fp_t_tcb_8, vec2(_63, _71)).xyzw;
    float _44 = _42.x;
    float _46 = _42.y;
    float _48 = _42.z;
    precise float _90 = _46 * 0.19859699904918670654296875;
    precise float _97 = fma(_48, 0.0475700013339519500732421875, fma(_44, 0.753832995891571044921875, _90)) * fp_c3_1._m0[0].x;
    precise float _105 = _46 * 0.9417769908905029296875;
    precise float _110 = fma(_48, 0.012478999793529510498046875, fma(_44, 0.0457439981400966644287109375, _105)) * fp_c3_1._m0[0].x;
    precise float _119 = _46 * 0.0176020003855228424072265625;
    precise float _124 = fma(_48, 0.9836080074310302734375, fma(_44, -0.001210000016726553440093994140625, _119)) * fp_c3_1._m0[0].x;

    // CUSTOM: UI color space and brightness; the game's own matrix above is kept as the Vanilla path.
    vec3 ui_color = vec3(_97, _110, _124);
    if (RENODX_UI_COLOR_SPACE == RENODX_COLOR_SPACE_BT709) {
        vec3 ui_bt709 = RENODX_SDR_EOTF_EMULATION ? FefwEmulateGamma22(_42.xyz) : _42.xyz;
        ui_color = (FEFW_BT2020_FROM_BT709 * ui_bt709) * fp_c3_1._m0[0].x;
    }
    _32 = vec4(ui_color * RENODX_UI_BRIGHTNESS, _42.w);
}
