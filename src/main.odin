package main

import "core:fmt"
import "core:math"

import "world"

import "vendor:glfw"
import gl "vendor:OpenGL"

WIN_WIDTH :: 800
WIN_HEIGHT :: 600
WIN_NAME :: "World Preview"

ROTATION_SPEED :: 1.0
MOVE_SPEED :: 3.0
VIEW_RADIUS :: 6.5

WorldSettings :: struct {
    dimensions: [2]u32,
}

CameraSettings :: struct {
    free: bool,
}

FUCK :: true

main :: proc() {
    fmt.println("Starting...")

    if !glfw.Init() {
        fmt.eprintfln("GLFW Init Failed:\n\tReason: %s", glfw.GetError())
        return
    }

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    win := glfw.CreateWindow(800, 600, "World Preview", nil, nil) 
    defer glfw.DestroyWindow(win)

    if win == nil {
        fmt.eprintfln("Window Creation Failed: \nReason: %s", glfw.GetError())
        return
    }

    glfw.MakeContextCurrent(win)
    glfw.ShowWindow(win)
    
    gl.load_up_to(3, 3, glfw.gl_set_proc_address)
    ui_ctx, err := init_ui(win)

    gl.Viewport(0, 0, 800, 600)
    
    if err != .None {
        fmt.printfln("Error Initializing UI: %s", err)
        return
    }

    defer deinit_ui(&ui_ctx)

    for !glfw.WindowShouldClose(win) {

        gl.ClearColor(1.0, 0.0, 0.0, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        update_ui(&ui_ctx)

        glfw.SwapBuffers(win)
        glfw.PollEvents()
    }

    glfw.Terminate()
}

//CameraData :: struct {
//	camera: ray.Camera3D,
//    settings: CameraSettings,
//}
//
//camera_movement :: proc(cam: ^CameraData) {
//    rot_speed : f32 = ROTATION_SPEED * ray.GetFrameTime()
//    move_speed : f32 = MOVE_SPEED * ray.GetFrameTime()
//
//    screen_offset := [2]f32{
//        f32(ray.GetScreenWidth()) * 0.5,
//        f32(ray.GetScreenHeight()) * 0.5,
//    }
//
//    if ray.IsKeyReleased(.G) do cam.settings.free = !cam.settings.free
//
//	if cam.settings.free {
//
//        // camera rotatoin
//        mouse_pos := ray.GetMousePosition()
//
//        rotation_factor := [2]f32{
//            (mouse_pos.x - screen_offset.x) / screen_offset.x,
//            (mouse_pos.y - screen_offset.y) / screen_offset.y,
//        }
//        if ray.IsMouseButtonDown(.LEFT) {
//            ray.CameraPitch(&cam.camera, rotation_factor.y * -rot_speed, false, false, false)
//            ray.CameraYaw(&cam.camera, rotation_factor.x * -rot_speed, false)
//        }
//
//        if ray.IsKeyDown(.W) {
//            ray.CameraMoveForward(&cam.camera, move_speed, false)
//        } 
//        if ray.IsKeyDown(.S) {
//            ray.CameraMoveForward(&cam.camera, -move_speed, false)
//        }
//        if ray.IsKeyDown(.LEFT_SHIFT) {
//            ray.CameraMoveUp(&cam.camera, move_speed)
//        }
//        if ray.IsKeyDown(.SPACE) {
//            ray.CameraMoveUp(&cam.camera, -move_speed)
//        }
//	} else {
//		// handle input keys
//        ray.CameraYaw(&cam.camera, rot_speed, true)
//	}
//}
//
//main :: proc() {
//    wld_settings := WorldSettings{}
//    wld_settings.dimensions = {20, 20}
//
//	test_world := world.gen(wld_settings.dimensions.x, wld_settings.dimensions.y)
//	defer world.destroy(test_world)
//
//	world.print(test_world)
//
//	ray.InitWindow(WIN_WIDTH, WIN_HEIGHT, WIN_NAME)
//    
//    cam := CameraData{}
//    cam.settings.free = true
//	cam.camera = ray.Camera3D{}
//
//	cam.camera.fovy = 45.0
//	cam.camera.up = {0.0, 1.0, 0.0}
//	cam.camera.target = {0.0, 0.0, 0.0}
//	cam.camera.position = {0.0, VIEW_RADIUS, VIEW_RADIUS}
//	cam.camera.projection = .PERSPECTIVE
//
//	rotation: f32 = 0.0
//
//    ray.SetTargetFPS(60)
//
//    ctx, err := init_ui((glfw.WindowHandle)(ray.GetWindowHandle()))
//    if err != .None {
//        fmt.println("Failed to initialize UI: ", err)
//        return
//    }
//
//    ui_cam := ray.Camera2D{}
//    ui_cam.zoom = 1.0
//
//
//	for !ray.WindowShouldClose() {
//		ray.PollInputEvents()
//
//        camera_movement(&cam)
//
//		ray.BeginDrawing()
//		ray.ClearBackground(ray.BLACK)
//		ray.BeginMode3D(cam.camera)
//
//		world.render(test_world)
//
//		ray.EndMode3D()
//        ray.BeginMode2D(ui_cam)
//        
//
//        ray.EndMode2D()
//        update_ui(&ctx)
//		ray.EndDrawing()
//	}
//
//	ray.CloseWindow()
//}
