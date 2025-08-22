package main

import "core:fmt"
import "core:math"
import "world"

GOLDEN_RATIO :: 1.618033988749

// rectangles:
// 1 -- X Long Y Short
// 2 -- Y Long Z Short
// 3 -- Z Long X Short


/// Generates the initial points for the icosphere
/// by generating rectangles corresponding to a unit sphere
/// which are of the golden ratio
@(private = "file")
gen_initial_points :: proc(builder: ^world.MeshBuilder) {
	// half-widths of long and short sides of rectangles
	short_side := math.sqrt(f32(1.0 / (1.0 + GOLDEN_RATIO * GOLDEN_RATIO)))
	long_side := short_side * GOLDEN_RATIO

	// RECTANGLE 1
	world.builder_append_vertex(builder, {-long_side, -short_side, 0.0})
    world.builder_append_vertex(builder, {-long_side, short_side, 0.0})
	world.builder_append_vertex(builder, {long_side, -short_side, 0.0})
	world.builder_append_vertex(builder, {long_side, short_side, 0.0})

    // RECTANGLE 2
	world.builder_append_vertex(builder, {0.0, -long_side, -short_side})
    world.builder_append_vertex(builder, {0.0, -long_side, short_side})
	world.builder_append_vertex(builder, {0.0, long_side, -short_side})
	world.builder_append_vertex(builder, {0.0, long_side, short_side})

    // RECTANGLE 3
	world.builder_append_vertex(builder, {-short_side, 0.0, -long_side})
    world.builder_append_vertex(builder, {short_side, 0.0, -long_side})
	world.builder_append_vertex(builder, {-short_side, 0.0, long_side})
	world.builder_append_vertex(builder, {short_side, 0.0, long_side})

    // Triangulation
    //  A few things to note here:
    // When it comes to icosahedron triangulation, there are basically 2 cases:
    // 1. Long - Short - Short: Triangle starts on the long edge of a source rectangle and proceeds along a short edge of the consecutive rectangle
    // 2. Long - Long - Long: Triangle spans all 3 source rectangles

    // Long - Short - Short
    // 12 total
    for i in 0..<12 {
        base_index := ((i / 4) + 1) % 3 * 4 + (i % 2) * 2

        world.builder_append_index(builder, u32(i))
        world.builder_append_index(builder, u32(base_index))
        world.builder_append_index(builder, u32(base_index + 1))
    }

    // Long - Long - Long
    // 8 total (rest of faces of icosahedron)
    //TODO: Find a procedural solution to this just cuz
    // or switch it all to compile time
    extra_faces := [?]u32{
        0, 4, 8,
        0, 5, 10,
        1, 6, 8,
        1, 7, 10,
        2, 5, 11,
        2, 4, 9,
        3, 7, 11,
        3, 6, 9,
    }

    copy(builder.triangles[36:], extra_faces[0:])
}

gen_icosphere :: proc(num_subdivisions: u32) -> world.Mesh {
	mesh: world.Mesh
	builder := world.begin_build_sized_mesh(&mesh, 12, 60)

    gen_initial_points(&builder)

    world.finalize_mesh_from_builder(&builder)
	return mesh
}
