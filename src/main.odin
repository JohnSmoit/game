package main

import "core:fmt"
import "core:math"
import lin "core:math/linalg"

import "world"

import "vendor:glfw"
import gl "vendor:OpenGL"

WIN_WIDTH :: 800
WIN_HEIGHT :: 600
WIN_NAME :: "World Preview"

ROTATION_SPEED :: 1.0
MOVE_SPEED :: 3.0
VIEW_RADIUS :: 6.5

@(rodata)
CUBE_VERTS := [?]world.Vec3{
    {-0.5, -0.5, 0.5 },
    { 0.5, -0.5, 0.5 },
    { 0.5,  0.5, 0.5 },
    {-0.5,  0.5, 0.5 },

    {-0.5, -0.5, -0.5 },
    { 0.5, -0.5, -0.5 },
    { 0.5,  0.5, -0.5 },
    {-0.5,  0.5, -0.5 },
}

@(rodata)
CUBE_TRIS := [?]u32{
    0, 1, 2, 2, 0, 3,
    0, 5, 2, 3, 7, 4,
    4, 5, 6, 6, 4, 7
}

WorldSettings :: struct {
    dimensions: [2]u32,
}

CameraSettings :: struct {
    free: bool,
}

OPENGL_API_MAJOR :: 4
OPENGL_API_MINOR :: 5

move_camera :: proc(win: glfw.WindowHandle, cam: ^world.Camera) {
    move := world.Vec3{0, 0, 0}
    rot : f32 = 0

    if glfw.GetKey(win, glfw.KEY_D) == glfw.PRESS {
        move.x += 0.01
    }
    if glfw.GetKey(win, glfw.KEY_A) == glfw.PRESS {
        move.x -= 0.01
    }
    if glfw.GetKey(win, glfw.KEY_W) == glfw.PRESS {
        move.z += 0.01
    }
    if glfw.GetKey(win, glfw.KEY_S) == glfw.PRESS {
        move.z -= 0.01
    }
    if glfw.GetKey(win, glfw.KEY_Q) == glfw.PRESS {
        rot -= 0.01
    }
    if glfw.GetKey(win, glfw.KEY_E) == glfw.PRESS {
        rot += 0.01
    }

    cam.position += move
    cam.rotation_euler += rot
}

glfw_resize_callback :: proc "cdecl" (win: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height)
}

main :: proc() {
    fmt.println("Starting...")

    if !glfw.Init() {
        fmt.eprintfln("GLFW Init Failed:\n\tReason: %s", glfw.GetError())
        return
    }

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_API_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_API_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    win := glfw.CreateWindow(800, 600, "World Preview", nil, nil) 
    defer glfw.DestroyWindow(win)
    

    if win == nil {
        fmt.eprintfln("Window Creation Failed: \nReason: %s", glfw.GetError())
        return
    }

    glfw.MakeContextCurrent(win)
    glfw.ShowWindow(win)

    glfw.SetFramebufferSizeCallback(win, glfw_resize_callback)
    
    gl.load_up_to(OPENGL_API_MAJOR, OPENGL_API_MINOR, glfw.gl_set_proc_address)
    ui_ctx, err := init_ui(win)

    mesh : world.Mesh
    {
        mesh_builder := world.begin_build_sized_mesh(&mesh, len(CUBE_VERTS), len(CUBE_TRIS))
        defer world.finalize_mesh_from_builder(&mesh_builder)

        copy(mesh_builder.vertices, CUBE_VERTS[0:])
        copy(mesh_builder.triangles, CUBE_TRIS[0:])
    }


    defer world.destroy_mesh(&mesh)

    cam := world.Camera{
        fov = lin.PI / 4.0,
        far = 1000.0,
        near = 0.1,
        aspect = WIN_WIDTH / WIN_HEIGHT,
        position = {0.0, 0.0, 0.0},
        rotation_euler = 0,
    }

    shader, ok := world.shader_from_file("shaders/basic")
    if ok != nil {
        fmt.eprintln("Error occured loading shader (see logs for shader compilation issues")
        return
    }
    defer world.destroy_shader(&shader)

    gl.Viewport(0, 0, 800, 600)
    
    if err != .None {
        fmt.printfln("Error Initializing UI: %s", err)
        return
    }

    defer deinit_ui(&ui_ctx)

    world.shader_use(&shader)

    for !glfw.WindowShouldClose(win) {

        gl.ClearColor(0.0, 0.0, 0.0, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        move_camera(win, &cam)
        world.update_camera(&cam)

        world.shader_set_uniform(&shader, "model", mesh.model)
        world.shader_set_uniform(&shader, "view", cam.view)
        world.shader_set_uniform(&shader, "projection", cam.projection)

        world.draw_mesh(&mesh)
        update_ui(&ui_ctx)

        glfw.SwapBuffers(win)
        glfw.PollEvents()
    }

    glfw.Terminate()
}

