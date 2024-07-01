#version 150
#extension GL_ARB_explicit_attrib_location : enable

#include "/lib/settings.glsl"
#include "/lib/functions.glsl"

#define BLOCK_DAMAGE_COLOR_ENABLE //enables block damage color

uniform float alphaTestRef;
uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform int heldItemId;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 tint;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;

void main() {
	vec4 color = texture(gtexture, texcoord) * tint;
	if (color.a < alphaTestRef) discard;

    #ifdef BLOCK_DAMAGE_COLOR_ENABLE
    if(heldItemId == 270){
        color = vec4(151 / 255.0, 91 / 255.0, 2 / 255.0, 1.0);
    }
    else if(heldItemId == 274){
        color = vec4(35.0 / 255.0, 72.0 / 255.0, 60.0 / 255.0, 1.0);
    }
    else if(heldItemId == 257){
        
        color = vec4(252 / 255.0, 223 / 255.0, 235 / 255.0, 1.0);
    }
    else if(heldItemId == 285){
        color = vec4(0.92549019607, 0.41176470588, 0.53333333333, 1.0);
    }
    else if(heldItemId == 278){
        color = vec4(10 / 255.0, 54 / 255.0, 153 / 255.0, 1.0);
    }
    else if(heldItemId == 1000){
        color = vec4(58 / 255.0, 3 / 255.0, 57 / 255.0, 1.0);
    }else{
        color *= texture(lightmap, lmcoord);
    }
    #else
    color *= texture(lightmap, lmcoord);
    #endif

    colortex0Out = color;
	//colortex0Out = color;
}