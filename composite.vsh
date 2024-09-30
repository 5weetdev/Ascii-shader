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

#version 150

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

in vec2 vaUV0;
in vec3 vaPosition;

out vec2 texcoord;

void main() {
	gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	texcoord    = vaUV0;
}