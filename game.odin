package main

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
	ruby:      ^mrb.State,
	mruby_ctx: MrubyCtx,
	assets:    AssetSystem,
	input:     input.FrameInput,

	// Game Data
	entities:  EntityPool,
	player:    EntityHandle,
}


game_init :: proc(game: ^Game) {
	game.mruby_ctx.alloc_ref = make(map[uint]uint)
	game.mruby_ctx.ctx = context

	game.ruby = mrb.open_allocf(mruby_odin_allocf, &game.mruby_ctx)
	asset_system_init(&game.assets)
}

game_deinit :: proc(game: ^Game) {
	asset_system_deinit(&game.assets)
	mrb.close(game.ruby)
	delete(game.mruby_ctx.alloc_ref)
}
