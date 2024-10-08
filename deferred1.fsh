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

uniform float far;
uniform float near;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;

const float u_threshold = 0.2;
const float u_threshold_depth = 10.1;

#include "/lib/settings.glsl"
#include "/lib/functions.glsl"

in vec2 texcoord;

/* DRAWBUFFERS:03 */
out vec4 colortex0Out;
out vec4 colortex3Out;

void main() {    
    // Apply Sobel filter
    vec2 sobelResult = applySobel(colortex3, texcoord, false);
    vec2 sobelResultDepth = applySobel(depthtex0, texcoord, true);
    
    // Threshold the edge magnitude
    float edge = step(u_threshold, length(sobelResult));
    float edgeDepth = step(u_threshold_depth, length(sobelResultDepth));
    
    // Calculate edge vector
    vec2 edgeVector = normalize(sobelResult) * edge + normalize(sobelResultDepth) * edgeDepth;

    colortex0Out = vec4(texture(colortex0, texcoord).rgb, 1.0);
    colortex3Out = vec4((edgeVector + 1.0) * 0.5, 0.0, 1.0); // pass color
}
