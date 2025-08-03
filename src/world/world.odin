package world

import "core:time"
import rt "base:runtime"
import "core:fmt"
import "core:math"

import "core:math/rand"
import "core:math/noise"

import "core:mem"


print :: proc(wld: World) {
	fmt.println("Here's the layout of the world, I guess:")

	line := make([]u8, wld.width, context.temp_allocator)
	defer free_all(context.temp_allocator)

	for y in 0 ..< wld.height {
		for x in 0 ..< wld.width {
			t := tile(wld, x, y)
			val, success := fmt.enum_value_to_string(t.biome)

			line[x] = '?' if !success else (transmute(string)val)[0]
		}

		fmt.printfln("%d: %s", y, line)
	}
}


TileIteratorProc :: distinct (proc(_: World, _: u32, _: u32, _: ^Tile, _: rawptr))

each_tile :: proc(wld: World, func: TileIteratorProc, usr_data: rawptr) {
	for x in 0 ..< wld.width {
		for y in 0 ..< wld.height {
			func(wld, x, y, tile(wld, x, y), usr_data)
		}
	}
}

Biome :: enum {
	Ocean,
	Beach,
	Grassland,
	Forest,
	Desert,
	Mountains,
}

Tile :: struct {
	biome: Biome,
}


World :: distinct ^_World

@(private)
_World :: struct {
	tiles:     []Tile,
	allocator: mem.Allocator,
	width:     u32,
	height:    u32,
}

width :: proc(wld: World) -> u32 {
	return wld.width
}

height :: proc(wld: World) -> u32 {
	return wld.height
}

PERIOD :: 0.05
AMP :: 2.0

@(private = "file")
setup_tiles :: proc(wld: World) {
    seed := time.now()._nsec
    each_tile(wld, proc(wld: World, x, y: u32, tile: ^Tile, usr_data: rawptr) {
        seed := (^i64)(usr_data)^
        sample := [2]f64{
            f64(x) * PERIOD,
            f64(y) * PERIOD,
        }

        val := u32(math.floor(0.5 * (noise.noise_2d(seed, sample) + 1.0) * f32(len(Biome))))

        tile.biome = Biome(val)
    }, &seed)
}

tile :: proc(wld: World, x: u32, y: u32) -> ^Tile {
	return &wld.tiles[y * wld.width + x]
}

gen :: proc(w: u32, h: u32) -> World {
	new_wld := World(new(_World))

	new_wld.tiles = make([]Tile, w * h)
	new_wld.width = w
	new_wld.height = h
	new_wld.allocator = context.allocator

	setup_tiles(new_wld)

	return World(new_wld)
}

destroy :: proc(wld: World) {
	if (wld == nil) do return

	allocator := wld.allocator

	delete(wld.tiles)
	free(wld)
}
