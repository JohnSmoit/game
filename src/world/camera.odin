package world

import lin "core:math/linalg"
import "core:math"

Camera :: struct {
    view: Mat4,
    projection: Mat4,

    position: Vec3,
    rotation: lin.Quaternionf32,
    fov: f32,
    aspect: f32,
    near: f32,
    far: f32,
}


/// Call this after all transformations
update_camera :: proc(cam: ^Camera) {
    cam.view = lin.matrix4_translate(cam.position)
    cam.view = lin.mul(lin.matrix4_from_quaternion(cam.rotation), cam.view)


    cam.view = lin.inverse(cam.view)
    cam.projection = lin.matrix4_perspective(cam.fov, cam.aspect, cam.near, cam.far, false)
}
