#version 130
#extension GL_ARB_explicit_attrib_location : enable

uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex3;

const float edgeThreshold = 0.05;

#include "/lib/settings.glsl"

in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;


vec3 quantizeColor(vec3 color, float steps) {
    // Ensure steps is at least 2 to avoid division by zero
    steps = max(steps, 2.0);
    
    // Calculate the step size
    float stepSize = 1.0 / (steps - 1.0);
    
    // Quantize each channel
    vec3 quantized;
    quantized.r = round(color.r / stepSize) * stepSize;
    quantized.g = round(color.g / stepSize) * stepSize;
    quantized.b = round(color.b / stepSize) * stepSize;
    
    // Clamp the result to [0, 1] range
    return clamp(quantized, 0.0, 1.0);
}

vec2 getMapping(int index) {
    int x = index % 16;
    int y = index / 16;
    if (index == 0){
        return vec2(0.0, 6.0);
    } 
    return vec2(float(x), float(y));
}


void main() {
	vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
	vec2 chars          = vec2(viewWidth  / FONT_WIDTH        , viewHeight  / FONT_HEIGHT);
	vec2 nCharSize      = vec2(FONT_WIDTH / FONT_TEXTURE_WIDTH, FONT_HEIGHT / FONT_TEXTURE_HEIGHT); 
	vec2 charsInTexture = vec2(FONT_TEXTURE_WIDTH / FONT_WIDTH, FONT_TEXTURE_HEIGHT / FONT_HEIGHT);

    vec2 edgesMapping[4];
    edgesMapping[0] = vec2(nCharSize.x * 14.0, nCharSize.y * 2.0);  
    edgesMapping[1] = vec2(nCharSize.x * 11.0, nCharSize.y * 5.0);  
    edgesMapping[2] = vec2(nCharSize.x * 12.0, nCharSize.y * 7.0); 
    edgesMapping[3] = vec2(nCharSize.x * 12.0, nCharSize.y * 2.0); 

	// downscale
	vec2 downscaledCoord = floor(texcoord * chars) / chars;

    // avarage
	vec3 avarageColor = vec3(0.0);
	for(float i = 0.0; i < FONT_WIDTH; i += 1.0) {
		for(float j = 0.0; j < FONT_HEIGHT; j += 1.0) {
			avarageColor = avarageColor + texture(colortex3, downscaledCoord + vec2(texelSize.x * i, texelSize.y * j)).rgb;
		}
	}
	avarageColor = avarageColor / (FONT_WIDTH * FONT_HEIGHT);

	vec3 color = texture(colortex0, downscaledCoord).rgb;

	// Gray scale
	float intensity = dot(color.rgb, vec3(0.299, 0.587, 0.114)); 

	vec2 charIndex = vec2(15.0, 15.0);

    #ifdef EDGES
    // edge detection
    float ax = avarageColor.x;
    float ay = avarageColor.y;
    if((ax < (0.5 - edgeThreshold) && ay > (0.5 + edgeThreshold)) ||
        ax > (0.5 + edgeThreshold) && ay < (0.5 - edgeThreshold)) { 
        charIndex = edgesMapping[0];
    }
    else if((ax > edgeThreshold && ax < (0.5 - edgeThreshold) && ay < (0.5 - edgeThreshold)) ||
            (ax > (0.5 + edgeThreshold) && ay > (0.5 + edgeThreshold))) { 
        charIndex = edgesMapping[1];
    }
    else if(ay > edgeThreshold && (ay > (0.5 + edgeThreshold) || ay < (0.5 - edgeThreshold))){ 
        charIndex = edgesMapping[2]; 
    }
    else if(ax > edgeThreshold && (ax < (0.5 - edgeThreshold) || ax > (0.5 + edgeThreshold))) { 
        charIndex = edgesMapping[3];
    }
    #endif

    vec3 charColor;
    vec2 charCoord = mod(mod((vec2(texcoord.x, 1.0 - texcoord.y - (1.0 / viewWidth))) * vec2(chars.x, chars.y), 1.0) / charsInTexture, 1.0);
    if(charIndex.x > 13.0 && charIndex.y > 13.0){
        //intensity = intensity * intensity;
        #ifdef QUANTIZE_CHAR
        intensity = floor(intensity * QUANTIZE_INTENSITY) / QUANTIZE_INTENSITY;
        #endif
        vec2 coord = getMapping(int(floor(intensity * 79.0))) * nCharSize;
        charColor = texture(colortex5, charCoord + coord).rgb;
    }
    else{
	    charColor = texture(colortex4, charCoord + charIndex).rgb;
    }

    #ifdef COLOR
        #ifdef QUANTIZE_COLOR
	colortex0Out = vec4(charColor * quantizeColor(color * 2.5, QUANTIZE_COLOR_VALUE), 1.0);
        #else
    colortex0Out = vec4(charColor * color, 1.0);
        #endif
    #else
    colortex0Out = vec4(charColor, 1.0);
    #endif
}