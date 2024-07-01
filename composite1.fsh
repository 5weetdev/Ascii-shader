#version 130
#extension GL_ARB_explicit_attrib_location : enable

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex3;      

const float u_Curvature = 20.0;
const float u_ScanlineIntensity = 0.1;
const float u_ScanlineCount = 1.0;
const float u_Vignette = 0.3;
const vec2 u_RgbOffset = vec2(0.04);

#include "/lib/settings.glsl"

in vec2 texcoord;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;

vec2 curveRemapUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(u_Curvature, u_Curvature);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void main() {
    #ifdef POST_PROCESSING
	vec2 uv = texcoord;
    vec2 curvedUV = curveRemapUV(uv);
    
    // Check if the curved UV is outside the texture
    if (curvedUV.x < 0.0 || curvedUV.x > 1.0 || curvedUV.y < 0.0 || curvedUV.y > 1.0) {
        colortex0Out = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    // Apply RGB split
    vec2 redUV = curvedUV + u_RgbOffset * vec2(0.025, 0.0);
    vec2 greenUV = curvedUV;
    vec2 blueUV = curvedUV - u_RgbOffset * vec2(0.025, 0.0);
    
    vec3 color;
    color.r = texture(colortex0, redUV).r;
    color.g = texture(colortex0, greenUV).g;
    color.b = texture(colortex0, blueUV).b;
    
    // Apply scanlines
    float scanline = sin(curvedUV.y * u_ScanlineCount * 3.14159 * 2.0) * 0.5 + 0.5;
    color *= 1.0 - (scanline * u_ScanlineIntensity);
    
    // Apply vignette
    vec2 vignetteUV = curvedUV * (1.0 - curvedUV.yx);
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, u_Vignette);
    color *= vignette;

	colortex0Out = vec4(color, 1.0);
    #else
    colortex0Out = vec4(texture(colortex0, texcoord).rgb, 1.0);
    #endif
}