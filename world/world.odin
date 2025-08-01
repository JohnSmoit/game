package world

import rt "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/rand"
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

@(private = "file")
setup_tiles :: proc(wld: World) {
	for &tile in wld.tiles {
		tile.biome = rand.choice_enum(Biome)
	}
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
