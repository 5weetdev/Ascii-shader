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



// POST PROCESSING SHADER
#version 130
#extension GL_ARB_explicit_attrib_location : enable

#include "/lib/settings.glsl"

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
#ifdef RGB_SPLIT
const vec2 u_RgbOffset = vec2(0.04);
#else
const vec2 u_RgbOffset = vec2(0.00);
#endif

// Bloom settings
const float bloom_threshold = 0.9;
const float bloom_softThreshold = 0.1;
const float bloom_radius = 4.50;

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

// Optimized blur function using a separable gaussian blur
vec4 multiDirBlur(sampler2D tex, vec2 uv, vec2 resolution, float radius) {
    vec4 color = vec4(0.0);
    float total = 0.0;
    
    // Blur directions
    vec2 directions[8];
    directions[0] = vec2(1.0, 0.0);
    directions[1] = vec2(0.7071, 0.7071);
    directions[2] = vec2(0.0, 1.0);
    directions[3] = vec2(-0.7071, 0.7071);
    directions[4] = vec2(-1.0, 0.0);
    directions[5] = vec2(-0.7071, -0.7071);
    directions[6] = vec2(0.0, -1.0);
    directions[7] = vec2(0.7071, -0.7071);
    
    // Blur weights (you can adjust these for different blur patterns)
    float weights[3];
    weights[0] = 0.3829;
    weights[1] = 0.2415;
    weights[2] = 0.0926;
    
    // Multi-directional blur
    for (int i = 0; i < 8; i++) {
        vec2 dir = directions[i] * radius / resolution;
        
        color += texture(tex, uv) * weights[0];
        total += weights[0];
        
        for (int j = 1; j < 3; j++) {
            color += texture(tex, uv + dir * float(j)) * weights[j];
            color += texture(tex, uv - dir * float(j)) * weights[j];
            total += 2.0 * weights[j];
        }
    }
    
    return (vec4(1.0) - (vec4(1.0) - color) / total);
}

// Optimized threshold function
vec3 threshold(vec3 color) {
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float knee = bloom_threshold * bloom_softThreshold;
    float soft = brightness - bloom_threshold + knee;
    soft = clamp(soft, 0.0, 2.0 * knee);
    soft = soft * soft / (4.0 * knee + 0.00001);
    float contribution = max(soft, brightness - bloom_threshold);
    contribution /= max(brightness, 0.00001);
    return color * contribution;
}

// Tone mapping function
vec3 toneMap(vec3 color) {
    return color / (vec3(1.0) + color);
}

vec3 acesTonemap(vec3 color) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
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

    // Tonemapping
    #ifdef TONEMAP
    color = acesTonemap(color);
    #endif

    // Apply bloom
    #ifdef BLOOM
    vec2 viewResolution = vec2(viewWidth, viewHeight);
    vec3 blurredColor = multiDirBlur(colortex0, texcoord, viewResolution, bloom_radius).rgb;
    vec3 thresholdColor = threshold(blurredColor);

    vec3 bloomColor = color + (thresholdColor * (vec3(1.0) - color));
    color = bloomColor;
    #endif

    // Apply vignette
    vec2 vignetteUV = curvedUV * (1.0 - curvedUV.yx);
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, u_Vignette);
    color *= vignette;


	

    vec3 originalColor = texture(colortex3, texcoord).rgb;
    colortex0Out = vec4(mix(color, originalColor, OVERLAY_ORIGINAL), 1.0);
#else

    vec3 originalColor = texture(colortex3, texcoord).rgb;
    colortex0Out = vec4(mix(texture(colortex0, texcoord).rgb, originalColor, OVERLAY_ORIGINAL), 1.0);

#endif
}