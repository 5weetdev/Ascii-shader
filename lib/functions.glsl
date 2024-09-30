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

float LinearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near * far) / (far + near - z * (far - near));
}

vec4 applyKernel(sampler2D tex, vec2 uv, float[9] kernel, bool linearizeDepth) {
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    vec4 result = vec4(0.0);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(float(i), float(j)) * texelSize;
            float value = texture2D(tex, uv + offset).r;
            if (linearizeDepth) {
                value = LinearizeDepth(value);
            }
            result += vec4(value) * kernel[(i + 1) * 3 + (j + 1)];
        }
    }
    
    return result;
}

vec2 applySobel(sampler2D tex, vec2 uv, bool linearizeDepth) {
    float gx = dot(applyKernel(tex, uv, sobelX, linearizeDepth).rgb, vec3(0.299, 0.587, 0.114));
    float gy = dot(applyKernel(tex, uv, sobelY, linearizeDepth).rgb, vec3(0.299, 0.587, 0.114));
    return vec2(gx, gy);
}

vec4 applyDoG(sampler2D tex, vec2 uv) {
    return applyKernel(tex, uv, gaussian1, false) - applyKernel(tex, uv, gaussian2, false);
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