package main

import "core:fmt"
import "world"

main :: proc() {
    test_world := world.gen(20, 20)
    defer world.destroy(test_world)

    world.print(test_world)
}
