#version 450 core

layout (location = 0) in vec3 iPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


const vec4 colors[6] = {
    vec4(1.0, 0.0, 0.0, 1.0),
    vec4(0.0, 1.0, 0.0, 1.0),
    vec4(0.0, 0.0, 1.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(0.0, 1.0, 1.0, 1.0),
    vec4(1.0, 0.0, 1.0, 1.0),
};

out vec4 color;

void main() {
    mat4 transform = projection * view * model;
    gl_Position = transform * vec4(iPos, 1.0);

    int col_index = gl_VertexID / 4 % 6;
    color = colors[col_index];
}
