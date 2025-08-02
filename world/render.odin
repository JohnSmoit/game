package world

import "core:container/intrusive/list"
import "core:fmt"
import ray "vendor:raylib"
import rl "vendor:raylib/rlgl"

TILE_SIZE: f32 : 1.0

BiomeInfo :: struct {
	color:      ray.Color,
	height_mul: f32,
}

BiomeProperties := [Biome]BiomeInfo {
	.Ocean     = {ray.BLUE, 0.3},
	.Beach     = {ray.BEIGE, 0.4},
	.Forest    = {ray.DARKGREEN, 0.9},
	.Desert    = {ray.YELLOW, 0.9},
	.Grassland = {ray.LIME, 0.4},
	.Mountains = {ray.DARKGRAY, 1.5},
}

WorldRenderer :: struct {
    mesh: ray.Mesh,
}

@(private)
init_renderer :: proc(wld: World) {

}

render :: proc(wld: World) {
}
