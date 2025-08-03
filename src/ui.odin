package main

import "core:fmt"
import "core:sys/windows"
import im "imgui"

import "imgui/imgui_impl_glfw"
import "imgui/imgui_impl_opengl3"

import "vendor:glfw"
import gl "vendor:OpenGL"

HWND :: windows.HWND

UIContext :: struct {
    ctx: ^im.Context,
    io: ^im.IO,
}

UIErrors :: enum {
    None,
    InitFailed_OpenGL,
    InitFailed_GLFW,
}

init_ui :: proc(win: glfw.WindowHandle) -> (octx: UIContext, err: UIErrors) {
    ctx : UIContext
    im.CHECKVERSION()
    ctx.ctx = im.CreateContext()

    ctx.io = im.GetIO()
    ctx.io.ConfigFlags = {.NavEnableKeyboard, .NavEnableGamepad}

    if !imgui_impl_glfw.InitForOpenGL(win, true) do return {}, .InitFailed_GLFW
    if !imgui_impl_opengl3.Init("#version 330") {
        imgui_impl_glfw.Shutdown()
        return {}, .InitFailed_OpenGL
    }

    return ctx, .None
}

update_ui :: proc(ctx: ^UIContext) {
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    im.NewFrame()

    // Drawing goes here

    im.ShowDemoWindow()

    im.Render()
    imgui_impl_opengl3.RenderDrawData(im.GetDrawData())
}

deinit_ui :: proc(ctx: ^UIContext) {
    imgui_impl_opengl3.Shutdown()
    imgui_impl_glfw.Shutdown()
    im.DestroyContext(ctx.ctx)
}
