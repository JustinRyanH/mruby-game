package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import mrb "./mruby"


RubyCode :: struct {
	id:            u64,
	file_path:     cstring,
	last_mod_time: u64,
}

AssetSystem :: struct {
	ruby: [dynamic]RubyCode,
}

asset_system_init :: proc(as: ^AssetSystem) {
	as.ruby = make([dynamic]RubyCode, 0, 32)
}

asset_system_deinit :: proc(as: ^AssetSystem) {
	delete(as.ruby)
}

Game :: struct {
	ruby:   ^mrb.State,
	assets: AssetSystem,
	f:      f64,
}

game_init :: proc(game: ^Game) {
	game.ruby = mrb.open()
	asset_system_init(&game.assets)
}

game_deinit :: proc(game: ^Game) {
	asset_system_deinit(&game.assets)
	mrb.close(game.ruby)
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
