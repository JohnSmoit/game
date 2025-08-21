package world

import "base:runtime"
import "core:fmt"
import "core:mem"

import "core:io"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"

Shader :: struct {
	program:        GlHandle,
	uniforms_table: gl.Uniforms,
}

ShaderCompileError :: enum {
	None = 0,
    InvalidStage,
	Vertex,
	Fragment,
	Link,
	File,
    Unknown,
}

ShaderLoadError :: union #shared_nil {
	runtime.Allocator_Error,
	os.Error,
	ShaderCompileError,
}


@(private)
module_from_file :: proc(
	path: string,
	stage: u32,
	allocator := context.temp_allocator,
) -> (
	sh: GlHandle,
	err: ShaderLoadError,
) {
    extension : string = ".vert" if stage == gl.VERTEX_SHADER else ".frag"
	path := strings.concatenate([]string{path, extension}, allocator) or_return

	src, ok := os.read_entire_file(path, allocator)
	if !ok {
		err = ShaderCompileError.File
		sh = 0

		return
	}

	shader := gl.CreateShader(stage)

	src_str := cstring(raw_data(src))

	gl.ShaderSource(shader, 1, &src_str, nil)

	success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if bool(success) {
		msg_buf := make([]u8, MSG_LOG_SIZE, allocator)
		len: i32
		gl.GetShaderInfoLog(shader, MSG_LOG_SIZE, &len, raw_data(msg_buf))

		msg := msg_buf[0:len]
		fmt.eprintfln("Error linking program: %s", msg)

		switch (stage) {
		case gl.VERTEX_SHADER:
			return 0, ShaderCompileError.Vertex
		case gl.FRAGMENT_SHADER:
			return 0, ShaderCompileError.Fragment
        case:
            return 0, ShaderCompileError.Unknown
		}
	}

	return shader, ShaderCompileError.None
}

MSG_LOG_SIZE :: 512

shader_from_file :: proc(path: string) -> (sh: Shader, err: ShaderLoadError) {
	defer free_all(context.temp_allocator)

	vert_shader := module_from_file(path, gl.VERTEX_SHADER) or_return
    defer gl.DeleteShader(vert_shader)
	frag_shader := module_from_file(path, gl.FRAGMENT_SHADER) or_return
    defer gl.DeleteShader(frag_shader)

	program := gl.CreateProgram()

	gl.AttachShader(program, vert_shader)
	gl.AttachShader(program, frag_shader)

	gl.LinkProgram(program)

	status: i32
	gl.GetProgramiv(program, gl.LINK_STATUS, &status)
	if !bool(status) {
		msg_buf := make([]u8, MSG_LOG_SIZE, context.temp_allocator)
		len: i32
		gl.GetProgramInfoLog(program, MSG_LOG_SIZE, &len, raw_data(msg_buf))

		msg := msg_buf[0:len]

		fmt.eprintfln("Error linking program: %s", msg)

		return Shader{}, ShaderCompileError.Link
	}

	// get program uniforms
	uniforms := gl.get_uniforms_from_program(program)

	sh = Shader {
		program        = program,
		uniforms_table = uniforms,
	}
	err = nil

	return
}

shader_use :: proc(shader: ^Shader) {
    gl.UseProgram(shader.program)
}

shader_set_uniform :: proc(shader: ^Shader, name: string, val: $T) {
    uniform_info := shader.uniforms_table[name]
    copied := val
    when T == matrix[4, 4]f32 do gl.UniformMatrix4fv(uniform_info.location, 1, false, raw_data(&copied))
    when T == [4]f32 do gl.Uniform4fv(uniform_info.location, 1, raw_data(&copied))
    when T == [3]f32 do gl.Uniform3fv(uniform_info.location, 1, raw_data(&copied))
    when T == [2]f32 do gl.Uniform2fv(uniform_info.location, 1, raw_data(&copied))
    when T == f32 do gl.Uniform1f(uniform_info.location, val)
    when T == u32 || T == u64 do gl.Uniform1ui(uniform_info.location, val)
    when T == i32 || T == i64 do gl.Uniform1i(uniform_info.location, val)
}


destroy_shader :: proc(shader: ^Shader) {
    gl.DeleteProgram(shader.program)
    gl.destroy_uniforms(shader.uniforms_table)
}
