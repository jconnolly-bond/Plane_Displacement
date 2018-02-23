// vert.glsl
#version 150

uniform mat4 transform;
uniform sampler2D texture;
uniform float u_time;

in vec4 position;
in vec4 color;
in vec2 texCoord;
in vec3 vertNormal;

out vec4 vertColor;
out vec2 vertTexCoord;

void main() {
  vec4 t = texture2D(texture, vec2(texCoord.x, texCoord.y+u_time));
  float displacement  = t.r + t.g + t.b * 100;
  vec4 displacedPosition = position;
	displacedPosition.xyz -= vec3(0, 1, 0) * displacement;
  
  gl_Position = transform * displacedPosition;
  // vertColor = t;
  vertColor = color;
  vertTexCoord = texCoord;
}