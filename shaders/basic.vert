#version 450 core

layout (binding = 0) uniform Matrices {
    mat4 model;
    mat4 view;
    mat4 projection;
};

layout (location = 0) in vec3 iPos;

uniform vec4 base_color;

out vec4 color;

void main() {
    mat4 transform = projection * view * model;
    gl_Position = transform * vec4(iPos, 1.0);

    float color_multiplier = (1 + (gl_VertexIndex / 4)) * (1.0 / 6.0);
    color = base_color * color_multiplier;
}
