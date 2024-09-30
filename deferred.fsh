//            _____  _____ _____ _____                       
//     /\    / ____|/ ____|_   _|_   _|                      
//    /  \  | (___ | |      | |   | |                        
//   / /\ \  \___ \| |      | |   | |                        
//  / ____ \ ____) | |____ _| |_ _| |_                       
// /_/    \_\_____/_\_____|_____|_____|  _      _            
// | |           | ____|                | |    | |           
// | |__  _   _  | |____      _____  ___| |_ __| | _____   __
// | '_ \| | | | |___ \ \ /\ / / _ \/ _ \ __/ _` |/ _ \ \ / /
// | |_) | |_| |  ___) \ V  V /  __/  __/ || (_| |  __/\ V / 
// |_.__/ \__, | |____/ \_/\_/ \___|\___|\__\__,_|\___| \_/  
//         __/ |                                             
//        |___/                                              
//
// Feel free to change shader parameters and don't forget to
// Star me on github: https://github.com/5weetdev/Ascii-shader :D

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