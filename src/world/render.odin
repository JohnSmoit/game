package world

import ml "core:math/linalg"
import "base:runtime"
import gl "vendor:OpenGL"


GlHandle :: u32

GL_NULL :: 0

Vec3 :: [3]f32
Vec2 :: [2]f32
Mat4 :: matrix[4,4]f32

Mesh :: struct {
    verts_buf: GlHandle,
    tris_buf: GlHandle,
    vert_array: GlHandle,

    model: Mat4,
}

MeshBuilder :: struct {
    vertices: []Vec3,
    triangles: []u32,

    allocator: runtime.Allocator,

    mesh: ^Mesh,
}

rotate_mesh_euler :: proc(mesh: ^Mesh, rads: f32, axis: Vec3) {
    mesh.model = ml.matrix4_rotate_f32(rads, axis)
}

destroy_mesh :: proc(mesh: ^Mesh) {
    buffers := [?]GlHandle{mesh.verts_buf, mesh.tris_buf}
    gl.DeleteBuffers(2, &buffers[0])
    gl.DeleteVertexArrays(1, &mesh.vert_array)
}

render_mesh :: proc(mesh: ^Mesh) {
    gl.BindVertexArray(mesh.vert_array)
}

begin_build_sized_mesh :: proc(mesh: ^Mesh, verts_count: u32, tris_count: u32) -> MeshBuilder {
    mesh.verts_buf = 0
    mesh.tris_buf = 0

    return MeshBuilder {
        vertices = make([]Vec3, verts_count, context.allocator),
        triangles = make([]u32, tris_count, context.allocator),
        allocator = context.allocator,
    }
}

finalize_from_builder :: proc(builder: ^MeshBuilder) {
    buffers : [2]u32
    gl.GenBuffers(len(buffers), &buffers[0])

    builder.mesh.verts_buf = buffers[0]
    builder.mesh.tris_buf = buffers[1]

    gl.GenVertexArrays(1, &builder.mesh.vert_array)

    gl.BindVertexArray(builder.mesh.vert_array)

    gl.BindBuffer(gl.ARRAY_BUFFER, builder.mesh.verts_buf)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, builder.mesh.tris_buf)

    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vec3), 0)
    gl.BufferData(gl.ARRAY_BUFFER, len(builder.vertices), raw_data(builder.vertices), gl.STATIC_DRAW)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(builder.triangles), raw_data(builder.triangles), gl.STATIC_DRAW)

    gl.BindVertexArray(0)

    delete(builder.vertices, builder.allocator)
}
