package main

import "core:fmt"
import "core:math/rand"
import "core:runtime"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"

Entity :: struct {
	pos:   rl.Vector2,
	size:  rl.Vector2,
	color: rl.Color,
}

EntityHandle :: distinct dp.Handle

EntityPool :: dp.DataPool(128, Entity, EntityHandle)

Game :: struct {
	ruby:     ^mrb.State,
	ctx:      runtime.Context,
	assets:   AssetSystem,
	input:    input.FrameInput,
	rand:     rand.Rand,

	// Game Data
	entities: EntityPool,
}

game_init :: proc(game: ^Game) {
	game.ctx = context
	fmt.println(game.rand)
	game.ruby = mrb.open_allocf(mruby_odin_allocf, &game.ctx)
	asset_system_init(&game.assets)
}

game_deinit :: proc(game: ^Game) {
	asset_system_deinit(&game.assets)
	mrb.close(game.ruby)
}
