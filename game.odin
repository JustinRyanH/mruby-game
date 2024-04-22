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

CollisionTargets :: [dynamic]EntityHandle

Game :: struct {
	ruby:             ^mrb.State,
	ctx:              runtime.Context,
	assets:           AssetSystem,
	input:            input.FrameInput,
	rand:             rand.Rand,

	// Temp Data
	collision_evts_t: map[EntityHandle]CollisionTargets,

	// Game Data
	entities:         EntityPool,
}

game_init :: proc(game: ^Game) {
	game.ctx = context
	game.rand = rand.create(1)
	game.ruby = mrb.open_allocf(mruby_odin_allocf, &game.ctx)
	asset_system_init(&game.assets)
}

game_setup_temp :: proc(game: ^Game) {
	game.collision_evts_t = make(map[EntityHandle]CollisionTargets, 16, context.temp_allocator)
}

game_deinit :: proc(game: ^Game) {
	asset_system_deinit(&game.assets)
	mrb.close(game.ruby)
}
