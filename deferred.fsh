#version 130
#extension GL_ARB_explicit_attrib_location : enable

// Do not remove this uniforms
uniform float far;
uniform float near;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D colortex0;

#include "/lib/settings.glsl"
#include "/lib/functions.glsl"

in vec2 texcoord;

/* DRAWBUFFERS:03 */
out vec4 colortex0Out;
out vec4 colortex3Out;

void main() {
	vec3 color = texture(colortex0, texcoord).rgb;

	// Apply Difference of Gaussians
    vec4 dogResult = applyDoG(colortex0, texcoord);

	colortex0Out = vec4(color.rgb , 1.0);
	colortex3Out = vec4(dogResult.rgb, 1.0);
}