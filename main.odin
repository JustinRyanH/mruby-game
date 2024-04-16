package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import mrb "./mruby"
import "./utils"

AssetError :: enum {
	NoAssetError,
}


RubyCodeHandle :: distinct u64

RubyCode :: struct {
	id:            RubyCodeHandle,
	file_path:     string,
	last_mod_time: u64,
	code:          string,
}

AssetSystem :: struct {
	ruby: map[RubyCodeHandle]RubyCode,
}

asset_system_init :: proc(as: ^AssetSystem) {
	as.ruby = make(map[RubyCodeHandle]RubyCode, 32)
}

asset_system_deinit :: proc(as: ^AssetSystem) {
	delete(as.ruby)
}

asset_system_load_ruby :: proc(as: ^AssetSystem, file: string) {
	handle := transmute(RubyCodeHandle)utils.generate_u64_from_string(file)
	if handle in as.ruby {
		// TODO: Reload if the mod time has changed
		panic("Unimplemented")
	}

	write_time, write_time_err := os.last_write_time_by_name(file)
	if write_time_err != os.ERROR_NONE {
		// TODO: Return error over panic
		panic(fmt.tprintf("Filed to access %s with err %v", file, write_time_err))
	}

	ruby_code, read_ruby_code_success := os.read_entire_file(file)
	assert(read_ruby_code_success, fmt.tprintf("Failed to open %s", file))

	code := RubyCode{handle, file, cast(u64)write_time, string(ruby_code)}
	as.ruby[handle] = code
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

	asset_system_load_ruby(&g.assets, "foo.rb")

	rl.InitWindow(1280, 800, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()
	}
}
