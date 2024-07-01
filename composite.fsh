#version 130
#extension GL_ARB_explicit_attrib_location : enable

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;



#include "/lib/settings.glsl"

in vec2 texcoord;

const float u_threshold = 0.33;
const float edgeThreshold = 0.1;        
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 colortex0Out;


// Precomputed Gaussian kernels
const float gaussian1[9] = float[](
    0.0947416, 0.118318, 0.0947416,
    0.118318, 0.147761, 0.118318,
    0.0947416, 0.118318, 0.0947416
);

const float gaussian2[9] = float[](
    0.0162162, 0.0540540, 0.0162162,
    0.0540540, 0.1216216, 0.0540540,
    0.0162162, 0.0540540, 0.0162162
);

// Precomputed Sobel kernels
const float sobelX[9] = float[](
    -1.0, 0.0, 1.0,
    -2.0, 0.0, 2.0,
    -1.0, 0.0, 1.0
);

const float sobelY[9] = float[](
    -1.0, -2.0, -1.0,
     0.0,  0.0,  0.0,
     1.0,  2.0,  1.0
);

vec4 applyKernel(sampler2D tex, vec2 uv, float[9] kernel) {
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    vec4 result = vec4(0.0);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * texelSize;
            result += texture2D(tex, uv + offset) * kernel[(i + 1) * 3 + (j + 1)];
        }
    }
    
    return result;
}

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

vec4 applyDoG(sampler2D tex, vec2 uv) {
    return applyKernel(tex, uv, gaussian1) - applyKernel(tex, uv, gaussian2);
}

vec2 applySobel(sampler2D tex, vec2 uv) {
    float gx = dot(applyKernel(tex, uv, sobelX).rgb, vec3(0.299, 0.587, 0.114));
    float gy = dot(applyKernel(tex, uv, sobelY).rgb, vec3(0.299, 0.587, 0.114));
    return vec2(gx, gy);
}


void main() {
	vec2 texelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);
	vec2 chars          = vec2(viewWidth  / FONT_WIDTH        , viewHeight  / FONT_HEIGHT);
	vec2 nCharSize      = vec2(FONT_WIDTH / FONT_TEXTURE_WIDTH, FONT_HEIGHT / FONT_TEXTURE_HEIGHT); 
	vec2 charsInTexture = vec2(FONT_TEXTURE_WIDTH / FONT_WIDTH, FONT_TEXTURE_HEIGHT / FONT_HEIGHT);

    float numOfChars = 9.0;

    vec2 mapping[9];
	mapping[0] = vec2(nCharSize.x * 15.0, nCharSize.y * 15.0);
	mapping[1] = vec2(nCharSize.x * 13.0, nCharSize.y * 2.0);
	mapping[2] = vec2(nCharSize.x * 9.0, nCharSize.y * 6.0);
	mapping[3] = vec2(nCharSize.x * 4.0, nCharSize.y * 7.0);
	mapping[4] = vec2(nCharSize.x * 1.0, nCharSize.y * 4.0);
	mapping[5] = vec2(nCharSize.x * 10.0, nCharSize.y * 2.0);
	mapping[6] = vec2(nCharSize.x * 12.0, nCharSize.y * 3.0);
	mapping[7] = vec2(nCharSize.x *  2.0, nCharSize.y * 2.0);
	mapping[8] = vec2(nCharSize.x *  0.0, nCharSize.y * 0.0);

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
			avarageColor = avarageColor + texture(colortex0, downscaledCoord + vec2(texelSize.x * i, texelSize.y * j)).rgb * 8.0;
		}
	}
	avarageColor = avarageColor / (FONT_WIDTH * FONT_HEIGHT);

	vec3 color = quantizeColor(texture(colortex1, downscaledCoord).rgb, numOfChars);
    vec3 colorUnscaled = texture(colortex0, texcoord).rgb;

	// Gray scale
	float intensity = dot(color.rgb, vec3(0.299, 0.587, 0.114)); 

	int mapIndex = int(round(intensity * (numOfChars - 1.0)));

	vec2 charIndex = vec2(10.0, 10.0);

    // edge detection
    if((avarageColor.x < -edgeThreshold && avarageColor.y < -edgeThreshold) ||
        avarageColor.x > edgeThreshold && avarageColor.y < -edgeThreshold){
        charIndex = edgesMapping[0];
    }
    else if(
             avarageColor.x > edgeThreshold && avarageColor.y > edgeThreshold){
        charIndex = edgesMapping[1];
    }
    else if(avarageColor.y > edgeThreshold || avarageColor.y < -edgeThreshold){
        charIndex = edgesMapping[2];
    }
    else if(avarageColor.x < -edgeThreshold || avarageColor.x > edgeThreshold){
        charIndex = edgesMapping[3];
    }else{
        charIndex = mapping[mapIndex];
    }

	vec2 charCoord = mod(mod((vec2(texcoord.x, 1.0 - texcoord.y - (1.0 / viewWidth))) * vec2(chars.x, chars.y), 1.0) / charsInTexture, 1.0);
	vec3 charColor = texture(colortex4, charCoord + charIndex).rgb;


	// Apply Difference of Gaussians
    vec4 dogResult = applyDoG(colortex0, texcoord);
    
    // Apply Sobel filter
    vec2 sobelResult = applySobel(colortex0, texcoord);
    
    // Calculate edge magnitude
    float edgeMagnitude = length(sobelResult);
    
    // Threshold the edge magnitude
    float edge = step(u_threshold, edgeMagnitude);
    
    // Calculate edge vector
    vec2 edgeVector = normalize(sobelResult) * edge;

    // Sample the font texture
    vec3 sampledColor = color * charColor.rgb;

	colortex0Out = vec4(charColor, 1.0);
}