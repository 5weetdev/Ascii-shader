#version 150
#extension GL_ARB_explicit_attrib_location : enable

#include "/lib/settings.glsl"

uniform float alphaTestRef;
uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform sampler2D noisetex;
uniform sampler2D colortex4; 

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;
in float dist;
in float grassLOD;

/* DRAWBUFFERS:0 */
out vec4 colortex0Out;

void main() {
	vec4 fcolor;
	if(grassLOD >= 0.5){
		// Chooses texture based on distance
		if(dist < GRASS_LOD_DISTANCE){
			if(grassLOD <= 1.5){
				fcolor = vec4(vec3(texture2D(colortex4, texcoord).r), texture2D(colortex4, texcoord).r);
			}else{
				fcolor = vec4(vec3(texture2D(colortex4, texcoord).g), texture2D(colortex4, texcoord).g);
			}
		}else{
			fcolor = vec4(vec3(texture2D(colortex4, texcoord).b), texture2D(colortex4, texcoord).b);
		}

		if (fcolor.a < alphaTestRef) discard;

		fcolor.rgb *= color.rgb;
		fcolor *= texture(lightmap, lmcoord); // Adds light
		colortex0Out = fcolor;
	}else{
		// Default terrain shader
		fcolor = texture(gtexture, texcoord);
		if (fcolor.a < alphaTestRef) discard;
		fcolor *= vec4(color.rgb, 1.0) * texture(lightmap, lmcoord) * color.aaaa;
		colortex0Out = fcolor;
	}
}