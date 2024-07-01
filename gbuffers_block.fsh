#version 150
#extension GL_ARB_explicit_attrib_location : enable

uniform float alphaTestRef;
uniform sampler2D gtexture;
uniform sampler2D lightmap;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 tint;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 fracolortex0;

void main() {
	vec4 color = texture(gtexture, texcoord) * tint;
	if (color.a < alphaTestRef) discard;
	color *= texture(lightmap, lmcoord);

	fracolortex0 = color;
}