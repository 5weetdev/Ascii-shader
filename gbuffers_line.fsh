#version 150
#extension GL_ARB_explicit_attrib_location : enable

#include "/lib/settings.glsl"
#include "/lib/functions.glsl"

#define TWO_PI 6.28318530718


uniform float alphaTestRef;
uniform float viewWidth;
uniform float viewHeight;

uniform float frameTimeCounter;

in vec4 tint;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;

void main() {
	vec4 color = tint;
	if (color.a < alphaTestRef) discard;

	#ifdef RAINBOW_LINES_ENABLE
        vec2 st = gl_FragCoord.xy/vec2(viewWidth, viewHeight);
        vec3 color2 = vec3(0.0);

        // Use polar coordinates instead of cartesian
        vec2 toCenter = vec2(0.5)-st;
        float angle = atan(toCenter.y,toCenter.x);
        float radius = length(toCenter) * -1.0;

        // Map the angle (-PI to PI) to the Hue (from 0 to 1)
        // and the Saturation to the radius
        color2 = hsb2rgb(vec3((angle/TWO_PI)+0.5 + frameTimeCounter * 0.25,radius + 1.0,1.0));
        colortex0Out = vec4(color2, 1.0);
    #else
        colortex0Out = color;
    #endif

}