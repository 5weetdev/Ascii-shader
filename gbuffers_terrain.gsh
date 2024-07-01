#version 150
//#extension GL_ARB_geometry_shader4 : enable
//const int maxVerticesOut = 6;

#include "/lib/settings.glsl"

#define GRASS_P1    -1.00

layout(triangles) in;
layout(triangle_strip, max_vertices = 255) out;

uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 modelViewMatrix;
uniform float frameTimeCounter;
uniform int blockEntityId;

uniform sampler2D noisetex;

uniform vec3 cameraPosition;

in vec2 gtexcoord[];
in vec2 gnoisecoord[];
in vec2 glmcoord[];
in vec4 gcolor[];
in vec3 gmc_Entity[];

out vec2 lmcoord;
out vec2 texcoord;
out vec4 color;
out float distanceToGrass;
out float grassLOD;

// Generates grass blade geomentry
void GenerateGrass(vec4 grass_pos, vec4 grass_color_top, vec4 grassbottom, float grass_height, float grass_width, float sizex){
  grass_pos = gbufferModelView * grass_pos;

  //  3 ─ ─ ─ ─ ─ ─ ─ 4
  //  │ +             │
  //  │   +           │
  //  │     +         │
  //  │       +       │
  //  │         +     │
  //  │           +   │
  //  │             + │
  //  1 ─ ─ ─ ─ ─ ─ ─ 2

  gl_Position = projectionMatrix * (grass_pos + vec4(-GRASS_WIDTH, 0.0, 0.0, 0.0)); // 1 left bottom

  texcoord = vec2(0.0, 0.0);
  lmcoord  = glmcoord[0];
  color    = grassbottom;

  EmitVertex();

  gl_Position = projectionMatrix * (grass_pos + vec4(GRASS_WIDTH, 0.0, 0.0, 0.0)); // 2 right bottom

  texcoord = vec2(1.0, 0.0);
  lmcoord  = glmcoord[1];
  color    = grassbottom;

  EmitVertex();

  gl_Position = projectionMatrix * (grass_pos + vec4(-GRASS_WIDTH + grass_width + // 3 left top
   GRASS_P1, GRASS_HEIGHT + sizex + grass_height + GRASS_P1 / 2, 0.0, 0.0));

  texcoord = vec2(0.0, -1.0);
  lmcoord  = glmcoord[2];
  color    = grass_color_top;

  EmitVertex();

  gl_Position = projectionMatrix * ( (grass_pos + vec4(GRASS_WIDTH + grass_width + // 4 right top
   GRASS_P1, GRASS_HEIGHT + sizex + grass_height + GRASS_P1 / 2, 0.0, 0.0)));

  texcoord = vec2(1.0, -1.0);
  lmcoord  = glmcoord[1];
  color    = grass_color_top;

  EmitVertex();
  EndPrimitive();
}

void main()
{	
  // Original geometry
  for(int i = 0; i < 3; i++)
  {
    vec4 vertex = gl_in[i].gl_Position;
    gl_Position = projectionMatrix * gbufferModelView * vertex;
    
    texcoord = gtexcoord[i];
    lmcoord  = glmcoord[i];
    color    = gcolor[i];
    if(gmc_Entity[0].x == 10100){
      grassLOD = -1.0;
    }else{
      grassLOD = 0.0;
    }
    
    EmitVertex();
  }
  EndPrimitive();

  // If it is grass block
  if(gmc_Entity[0].x == 10100)
  { 
    vec3 a = vec3(gl_in[0].gl_Position) - vec3(gl_in[1].gl_Position);
    vec3 b = vec3(gl_in[2].gl_Position) - vec3(gl_in[1].gl_Position);
    vec3 n = normalize(cross(a, b)); // Gets normal vector for given triangle

    // Distance to grass block
    distanceToGrass = dot(gl_in[0].gl_Position.xyz, gl_in[0].gl_Position.xyz);

    // If given triangle faces up and distance is less then GRASS_VIEW_DISTANCE
    if(n.x <= 0.1 && n.x >= -0.1 && n.z <= 0.1 && n.z >= -0.1 &&
    n.y < 0.0 && gbufferModelView[1][2] < 0.999 &&
    distanceToGrass < GRASS_VIEW_DISTANCE)
    {
      grassLOD = 1.0;
      // Makes bottom of grass blade little darker
      vec4 grassbottom = vec4(gcolor[0].rgb * 0.5, gcolor[0].a);
      vec4 grass_color_top = grassbottom;
      float grass_height = -GRASS_P1;
      float grass_width = -GRASS_P1;

      float sizex = max(gbufferModelView[1][2] * 0.4, 0);
      vec4 grass_pos = (gl_in[0].gl_Position + gl_in[1].gl_Position + gl_in[2].gl_Position) * 0.33;

      // Adds noise to color of grass top vertexies
      if(distanceToGrass < GRASS_LOD_DISTANCE){
        grass_color_top.rgb = gcolor[0].rgb * 0.7;
        grass_color_top.rgb *= mix(0.95, 1.15, sin(texture(noisetex, (gl_in[0].gl_Position.xz + cameraPosition.xz) / 64).x * 60) * 0.5 + 0.5);
      }
      
      //adds grass variations
      if(texture(noisetex, (gl_in[0].gl_Position.xz + cameraPosition.xz) / 64).x * 2 >= 0.6){
        grassLOD = 2.0;
      }

      if(distanceToGrass < GRASS_WAVING_DISTANCE){
        // Moves upper vertexies to imitate wind
        grass_height = texture(noisetex, gnoisecoord[0] * 0.8).r * 2 * GRASS_HEIGHT;
        grass_width  = texture(noisetex, gnoisecoord[0]).r       * 4 * GRASS_WIDTH;

        grass_pos.x += sin(texture(noisetex, vec2(gl_in[0].gl_Position.xz + cameraPosition.xz) * 0.015 ).r * 128) * 0.25;
        grass_pos.z += sin(texture(noisetex, vec2(gl_in[0].gl_Position.xz + cameraPosition.xz) * 0.0153).r * 128) * 0.25;
      }

      
      if(distanceToGrass > MORE_GRASS_DISTANCE * 0.5){
        grass_height += 0.1;
      }
      if(distanceToGrass > MORE_GRASS_DISTANCE){
        grass_height += 0.1;
      }
      
      //adds more grass geometry
      float offset = 0.33;
      vec4 posit = (gl_in[0].gl_Position + gl_in[1].gl_Position + grass_pos) * offset;
      GenerateGrass(posit, grass_color_top, grassbottom, grass_height, grass_width, sizex);
      if(distanceToGrass < MORE_GRASS_DISTANCE * 0.5){
        posit = (gl_in[0].gl_Position + grass_pos + gl_in[2].gl_Position) * offset;
        GenerateGrass(posit, grass_color_top, grassbottom, grass_height, grass_width, sizex);
        
      }
      if (distanceToGrass < MORE_GRASS_DISTANCE){
        posit = (grass_pos + gl_in[1].gl_Position + gl_in[2].gl_Position) * offset;
        GenerateGrass(posit, grass_color_top, grassbottom, grass_height, grass_width, sizex);
      }
    }
  }
}