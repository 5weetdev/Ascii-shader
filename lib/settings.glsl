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



#define FONT_TEXTURE_WIDTH 128.0
#define FONT_TEXTURE_HEIGHT 128.0
#define FONT_WIDTH 8.0
#define FONT_HEIGHT 8.0


#define COLOR // Enables color outline
#define QUANTIZE_COLOR // Enables quantization of color
#define QUANTIZE_CHAR // Enables quantization of characters
#define EDGES // Enables drwing edges with
#define TONEMAP // Enables tonemaping
//#define RGB_SPLIT // Splits rgb chanells
#define BLOOM // Applies a little bit of bloor to bright objects

#define OVERLAY_ORIGINAL 0.0 // [0.0 0.25 0.5 0.75 1.0] // Overlayes original image on top of characters
#define QUANTIZE_INTENSITY 8.0 // [1.0 2.0 4.0 8.0 12.0 16.0 24.0 32.0 64.0] // Sets quantization value for characters
#define QUANTIZE_COLOR_VALUE 16.0 // [1.0 2.0 4.0 8.0 12.0 16.0 24.0 32.0 64.0] // Sets quantization value for color

#define POST_PROCESSING // Enables post processing