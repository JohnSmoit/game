#version 450 core

layout (location = 0) in vec3 iPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


flat out uint index;

void main() {
    mat4 transform = projection * view * model;
    index = gl_VertexID;

    gl_Position = transform * vec4(iPos, 1.0);
}
