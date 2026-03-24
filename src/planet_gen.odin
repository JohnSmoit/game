package main

import "core:sync"
import "core:container/queue"
import "core:fmt"
import "core:math"
import lin "core:math/linalg"
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
	append(&builder.vertices, world.Vec3{-long_side, -short_side, 0.0})
    append(&builder.vertices, world.Vec3{-long_side, short_side, 0.0})
	append(&builder.vertices, world.Vec3{long_side, -short_side, 0.0})
	append(&builder.vertices, world.Vec3{long_side, short_side, 0.0})

    // RECTANGLE 2
	append(&builder.vertices, world.Vec3{0.0, -long_side, -short_side})
    append(&builder.vertices, world.Vec3{0.0, -long_side, short_side})
	append(&builder.vertices, world.Vec3{0.0, long_side, -short_side})
	append(&builder.vertices, world.Vec3{0.0, long_side, short_side})

    // RECTANGLE 3
	append(&builder.vertices, world.Vec3{-short_side, 0.0, -long_side})
    append(&builder.vertices, world.Vec3{short_side, 0.0, -long_side})
	append(&builder.vertices, world.Vec3{-short_side, 0.0, long_side})
	append(&builder.vertices, world.Vec3{short_side, 0.0, long_side})

    // Triangulation
    //  A few things to note here:
    // When it comes to icosahedron triangulation, there are basically 2 cases:
    // 1. Long - Short - Short: Triangle starts on the long edge of a source rectangle and proceeds along a short edge of the consecutive rectangle
    // 2. Long - Long - Long: Triangle spans all 3 source rectangles

    // Long - Short - Short
    // 12 total
    for i in 0..<12 {
        base_index := ((i / 4) + 1) % 3 * 4 + (i % 2) * 2

        append(&builder.triangles, u32(i))
        append(&builder.triangles, u32(base_index))
        append(&builder.triangles, u32(base_index + 1))
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

    append(&builder.triangles, ..extra_faces[:])
}

SubdivisionTask :: struct {
    tri_index: u32, // multiple of 3 cuz 3 indices per triangle
    level: u8,
}

SubdivisionQueue :: queue.Queue(SubdivisionTask)

// subdivide an individual face if necessary (this is a good candidate for parallelizing)
@(private="file")
subdivide_face :: proc(builder: ^world.MeshBuilder, tasks: ^SubdivisionQueue, max_lvl: u8) {
    task := queue.pop_front(tasks)

    orig_index_a := builder.triangles[task.tri_index]
    orig_index_b := builder.triangles[task.tri_index + 1]
    orig_index_c := builder.triangles[task.tri_index + 2]

    new_index_a : u32 = u32(len(builder.vertices))
    new_index_b : u32 = u32(len(builder.vertices) + 1)
    new_index_c : u32 = u32(len(builder.vertices) + 2)


    orig_a := builder.vertices[orig_index_a]
    orig_b := builder.vertices[orig_index_b]
    orig_c := builder.vertices[orig_index_c]

    point_1 := lin.vector_slerp(orig_a, orig_b, 0.5)
    point_2 := lin.vector_slerp(orig_b, orig_c, 0.5)
    point_3 := lin.vector_slerp(orig_c, orig_a, 0.5)

    // This is bad but will do for now -- all the memory shifting is really gonna suck
    // for larger arrays
    append(&builder.vertices, point_1, point_2, point_3)

    // Delete the initial indices (they need to be remapped
    // to take the subdivision into account)
    //FIXME: This literally doesn't work because it shifts the indices
    // resulting in the other tasks referring to the wrong triangle indicies oops
    ordered_remove(&builder.triangles, task.tri_index)
    ordered_remove(&builder.triangles, task.tri_index + 1)
    ordered_remove(&builder.triangles, task.tri_index + 2)

    // create new tasks if neccesary
    if task.level < max_lvl {
        for i in 0..<4 {
            queue.push_back(tasks, SubdivisionTask{
                tri_index = u32(len(builder.triangles) + (i * 3)),
                level = task.level + 1,
            })
        }
    }
    
    // finally, triangulate the new vertices into the mesh
    new_indices := [?]u32{
        orig_index_a, new_index_a, new_index_c,
        new_index_a, orig_index_c,  new_index_b,
        new_index_a, new_index_b, new_index_c,
        new_index_c, new_index_b, orig_index_b,
    }

    fmt.println(new_indices)
   
    append(&builder.triangles, ..new_indices[:])

}

@(private="file")
handle_subdivisions :: proc(builder: ^world.MeshBuilder, max_lvl: u8) {
    if max_lvl == 0 {
        fmt.println("Yeet")
        return
    }

    tasks_queue : SubdivisionQueue
    queue.init(&tasks_queue)
    
    // handle subdivision of initial triangles
    for i in 0..<20 {
        queue.push_back(&tasks_queue, SubdivisionTask{
            tri_index = u32(i * 3),
            level = 1,
        })
    }
    
    // parallelization woudl start here
    for queue.len(tasks_queue) != 0 {
        subdivide_face(builder, &tasks_queue, max_lvl)
    }
}

gen_icosphere :: proc(num_subdivisions: u8) -> world.Mesh {
	mesh: world.Mesh
	builder := world.begin_build_mesh_dynamic(&mesh)

    gen_initial_points(&builder)

    handle_subdivisions(&builder, num_subdivisions)

    world.finalize_mesh_from_builder(&builder)
	return mesh
}
