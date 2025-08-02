package main

import "core:fmt"
import "core:math"

import ray "vendor:raylib"
import "world"


WIN_WIDTH :: 800
WIN_HEIGHT :: 600
WIN_NAME :: "World Preview"

ROTATION_SPEED :: 1.0
MOVE_SPEED :: 3.0
VIEW_RADIUS :: 6.5


CameraData :: struct {
	camera: ray.Camera3D,
    free: bool,
}

camera_movement :: proc(cam: ^CameraData) {

    rot_speed : f32 = ROTATION_SPEED * ray.GetFrameTime()
    move_speed : f32 = MOVE_SPEED * ray.GetFrameTime()

    screen_offset := [2]f32{
        f32(ray.GetScreenWidth()) * 0.5,
        f32(ray.GetScreenHeight()) * 0.5,
    }

    if ray.IsKeyReleased(.G) do cam.free = !cam.free

	if cam.free {

        // camera rotatoin
        mouse_pos := ray.GetMousePosition()

        rotation_factor := [2]f32{
            (mouse_pos.x - screen_offset.x) / screen_offset.x,
            (mouse_pos.y - screen_offset.y) / screen_offset.y,
        }
        if ray.IsMouseButtonDown(.LEFT) {
            ray.CameraPitch(&cam.camera, rotation_factor.y * -rot_speed, false, false, false)
            ray.CameraYaw(&cam.camera, rotation_factor.x * -rot_speed, false)
        }

        if ray.IsKeyDown(.W) {
            ray.CameraMoveForward(&cam.camera, move_speed, false)
        } 
        if ray.IsKeyDown(.S) {
            ray.CameraMoveForward(&cam.camera, -move_speed, false)
        }
        if ray.IsKeyDown(.LEFT_SHIFT) {
            ray.CameraMoveUp(&cam.camera, move_speed)
        }
        if ray.IsKeyDown(.SPACE) {
            ray.CameraMoveUp(&cam.camera, -move_speed)
        }
	} else {
		// handle input keys
        ray.CameraYaw(&cam.camera, rot_speed, true)
	}
}

main :: proc() {
	test_world := world.gen(40, 40)
	defer world.destroy(test_world)

	world.print(test_world)

	ray.InitWindow(WIN_WIDTH, WIN_HEIGHT, WIN_NAME)
    
    cam := CameraData{}
    cam.free = true
	cam.camera = ray.Camera3D{}

	cam.camera.fovy = 45.0
	cam.camera.up = {0.0, 1.0, 0.0}
	cam.camera.target = {0.0, 0.0, 0.0}
	cam.camera.position = {0.0, VIEW_RADIUS, VIEW_RADIUS}
	cam.camera.projection = .PERSPECTIVE

	rotation: f32 = 0.0

    ray.SetTargetFPS(60)

	for !ray.WindowShouldClose() {
		ray.PollInputEvents()

        camera_movement(&cam)

		ray.BeginDrawing()
		ray.ClearBackground(ray.BLACK)
		ray.BeginMode3D(cam.camera)

		world.render(test_world)

		ray.EndMode3D()
		ray.EndDrawing()
	}

	ray.CloseWindow()
}
