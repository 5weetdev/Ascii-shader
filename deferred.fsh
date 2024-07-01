#version 130
#extension GL_ARB_explicit_attrib_location : enable

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

uniform sampler2D colortex0;
uniform sampler2D colortex4;

//const bool 4Clear = false;
//const bool 1Clear = false;

#include "/lib/settings.glsl"

in vec2 texcoord;

const float u_threshold = 0.5;

/* DRAWBUFFERS:0 1 */
layout(location = 0) out vec4 colortex0Out;
layout(location = 1) out vec4 colortex1Out;


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


	// downscale
	vec2 downscaledCoord = floor(texcoord * chars) / chars;

	vec3 color = texture(colortex0, downscaledCoord).rgb;
	vec3 colorUnscaled = texture(colortex0, texcoord).rgb;

	// Gray scale
	float intensity = dot(color.rgb, vec3(0.299, 0.587, 0.114)); 

	float numOfChars = 3.0;

	vec2 mapping[3];
	mapping[0] = vec2(nCharSize.x * 15.0, nCharSize.y * 15.0);
	mapping[1] = vec2(nCharSize.x * 15.0, nCharSize.y * 2.0);
	mapping[2] = vec2(nCharSize.x *  0.0, nCharSize.y * 0.0);

	int mapIndex = int(round(intensity * (numOfChars - 1.0)));

	vec2 charIndex = mapping[mapIndex];

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

	colortex0Out = vec4(dogResult.rgb, 1.0);
	colortex1Out = vec4(colorUnscaled.rgb, 1.0);
}