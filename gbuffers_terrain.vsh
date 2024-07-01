#version 150

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 textureMatrix = mat4(1.0);
uniform vec3 chunkOffset;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

#include "/lib/settings.glsl"

uniform sampler2D noisetex;

in ivec2 vaUV2;
in vec2 vaUV0;
in vec3 vaPosition;
in vec4 vaColor;

in vec3 mc_Entity;

out vec2 glmcoord;
out vec2 gtexcoord;
out vec2 gnoisecoord;
out vec4 gcolor;
out vec3 gmc_Entity;

void main() {
	vec4 vertex = vec4(vaPosition + chunkOffset, 1.0);
	gnoisecoord = (vertex.xz + cameraPosition.xz) / 64 + (frameTimeCounter / 32);
	gl_Position = vertex;

	//todo mip texutre
	gtexcoord   = (textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;
	glmcoord    = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);
	gcolor      = vaColor;

	gmc_Entity  = mc_Entity;
}