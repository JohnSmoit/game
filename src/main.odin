package main

import "core:mem"
import "core:fmt"
import "core:math"
import lin "core:math/linalg"

import "world"

import "vendor:glfw"
import gl "vendor:OpenGL"

WIN_WIDTH :: 800
WIN_HEIGHT :: 600
WIN_NAME :: "World Preview"

OPENGL_API_MAJOR :: 4
OPENGL_API_MINOR :: 5

MOUSE_MULT :: 1.0

move_camera :: proc(win: glfw.WindowHandle, cam: ^world.Camera) {
    @(static) old_x, old_y : f64 = 0, 0
    @(static) cam_rot_x, cam_rot_y : f32 = 0, 0
    move := world.Vec3{0, 0, 0}
    rot : f32 = 0

    mousex, mousey : f64 = glfw.GetCursorPos(win)

    mousex = (mousex / WIN_WIDTH - 0.5) * 2.0
    mousey = (mousey / WIN_HEIGHT - 0.5) * 2.0

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
        move.y -= 0.01
    }
    if glfw.GetKey(win, glfw.KEY_E) == glfw.PRESS {
        move.y += 0.01
    }

    cam.position += move

    cam_rot_x += f32(mousex - old_x) * MOUSE_MULT
    cam_rot_y += f32(mousey - old_y) * MOUSE_MULT



    cam.rotation = lin.quaternion_from_pitch_yaw_roll(cam_rot_y, cam_rot_x, 0)


    old_x = mousex
    old_y = mousey
}

glfw_resize_callback :: proc "cdecl" (win: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height)
}


main :: proc() {
    fmt.println("Starting...")

    // Setup tracking allocator for memory leak detection
    when ODIN_DEBUG {
        fmt.println("   ...in debug mode.")

        allocator : mem.Tracking_Allocator
        mem.tracking_allocator_init(&allocator, context.allocator)
        context.allocator = mem.tracking_allocator(&allocator)

        defer {
            if len(allocator.allocation_map) != 0 {
                for _, entry in allocator.allocation_map {
                    fmt.eprintfln("-- %d bytes leaked at %v", entry.size, entry.location)
                }
            }
        }
    }


    if !glfw.Init() {
        fmt.eprintfln("GLFW Init Failed:\n\tReason: %s", glfw.GetError())
        return
    }
    defer glfw.Terminate()

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

    mesh := gen_icosphere(1)
    defer world.destroy_mesh(&mesh)

    fmt.printfln("Number of elements: %d", mesh.elem_count)

    cam := world.Camera{
        fov = lin.PI / 4.0,
        far = 1000.0,
        near = 0.1,
        aspect = WIN_WIDTH / WIN_HEIGHT,
        position = {0.0, 0.0, -1.0},
    }

    shader, ok := world.shader_from_file("shaders/basic")
    if ok != nil {
        fmt.eprintln("Error occured loading shader (see logs for shader compilation issues")
        return
    }
    defer world.destroy_shader(&shader)

    gl.Viewport(0, 0, 800, 600)
    gl.Enable(gl.DEPTH_TEST)
    
    if err != .None {
        fmt.printfln("Error Initializing UI: %s", err)
        return
    }

    defer deinit_ui(&ui_ctx)

    world.shader_use(&shader)

    for !glfw.WindowShouldClose(win) {

        gl.ClearColor(0.0, 0.0, 0.0, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

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
}

