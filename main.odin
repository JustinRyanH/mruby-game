package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import mrb "./mruby"


Game :: struct {
	f: f64,
}


g: ^Game

main :: proc() {
	g = new(Game)
	defer free(g)
	state := mrb.open()
	defer mrb.close(state)

	rl.InitWindow(1280, 800, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()


	}
}
