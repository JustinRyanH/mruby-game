package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import mrb "./mruby"


Game :: struct {
	ruby: ^mrb.State,
	f:    f64,
}

game_init :: proc(game: ^Game) {
	game.ruby = mrb.open()
}

game_deinit :: proc(game: ^Game) {
	defer mrb.close(game.ruby)
}


g: ^Game

main :: proc() {
	g = new(Game)
	defer free(g)

	game_init(g)
	defer game_deinit(g)

	rl.InitWindow(1280, 800, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()


	}
}
