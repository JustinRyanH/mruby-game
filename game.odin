package main

import "./input"
import mrb "./mruby"

Game :: struct {
	ruby:      ^mrb.State,
	mruby_ctx: MrubyCtx,
	assets:    AssetSystem,
	input:     input.FrameInput,
	f:         f64,
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
