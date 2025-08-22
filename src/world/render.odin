package world

import "core:fmt"
import lin "core:math/linalg"
import "base:runtime"
import gl "vendor:OpenGL"


GlHandle :: u32

GL_NULL :: 0

Vec4 :: [4]f32
Vec3 :: [3]f32
Vec2 :: [2]f32
Mat4 :: matrix[4,4]f32

Mesh :: struct {
    verts_buf: GlHandle,
    tris_buf: GlHandle,
    vert_array: GlHandle,

    elem_count: uint,

    model: Mat4,
}

MeshBuilder :: struct {
    vertices: []Vec3,
    triangles: []u32,

    next_vertex: u32,
    next_index: u32,

    allocator: runtime.Allocator,

    mesh: ^Mesh,
}

begin_build_sized_mesh :: proc(mesh: ^Mesh, verts_count: uint, tris_count: uint) -> MeshBuilder {
    mesh.verts_buf = 0
    mesh.tris_buf = 0
    mesh.model = lin.identity_matrix(Mat4)

    return MeshBuilder {
        vertices = make([]Vec3, verts_count, context.allocator),
        triangles = make([]u32, tris_count, context.allocator),

        next_vertex = 0,
        next_index = 0,

        allocator = context.allocator,
        mesh = mesh,
    }
}

builder_append_vertex :: proc(builder: ^MeshBuilder, vert: Vec3) {
    if builder.next_vertex > u32(len(builder.vertices)) do return
    builder.vertices[builder.next_vertex] = vert;

    builder.next_vertex += 1
}

builder_append_index :: proc(builder: ^MeshBuilder, ind: u32) {
    if builder.next_index > u32(len(builder.triangles)) do return
    builder.triangles[builder.next_index] = ind;

    builder.next_index += 1
}

finalize_mesh_from_builder :: proc(builder: ^MeshBuilder) {
    buffers : [2]u32
    gl.GenBuffers(len(buffers), &buffers[0])

    builder.mesh.verts_buf = buffers[0]
    builder.mesh.tris_buf = buffers[1]
    builder.mesh.elem_count = len(builder.triangles)
    fmt.printfln("number of elements in mesh: %d", builder.mesh.elem_count)

    gl.GenVertexArrays(1, &builder.mesh.vert_array)

    gl.BindVertexArray(builder.mesh.vert_array)

    gl.BindBuffer(gl.ARRAY_BUFFER, builder.mesh.verts_buf)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, builder.mesh.tris_buf)

    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vec3), 0)
    gl.BufferData(gl.ARRAY_BUFFER, len(builder.vertices) * size_of(Vec3), raw_data(builder.vertices), gl.STATIC_DRAW)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(builder.triangles) * size_of(u32), raw_data(builder.triangles), gl.STATIC_DRAW)

    gl.BindVertexArray(0)

    delete(builder.vertices, builder.allocator)
    delete(builder.triangles, builder.allocator)
}

rotate_mesh_euler :: proc(mesh: ^Mesh, rads: f32, axis: Vec3) {
    mesh.model = lin.matrix4_rotate_f32(rads, axis)
}

/// Requires program to be used earlier
draw_mesh :: proc(mesh: ^Mesh) {
    gl.BindVertexArray(mesh.vert_array)
    gl.DrawElements(gl.TRIANGLES, i32(mesh.elem_count), gl.UNSIGNED_INT, nil)
}

destroy_mesh :: proc(mesh: ^Mesh) {
    buffers := [?]GlHandle{mesh.verts_buf, mesh.tris_buf}
    gl.DeleteBuffers(2, &buffers[0])
    gl.DeleteVertexArrays(1, &mesh.vert_array)
}
