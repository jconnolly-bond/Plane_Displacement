// frag.glsl
#version 150

uniform sampler2D texture;
uniform float u_time;

in vec4 vertColor;
in vec2 vertTexCoord;

out vec4 fragColor;

void main() {
  fragColor = vertColor;
  fragColor = mix(vertColor, texture2D(texture, vec2(vertTexCoord.x, vertTexCoord.y+u_time)), 0.5);
  fragColor.a = 0.75;
}