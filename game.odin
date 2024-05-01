package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:path/filepath"
import "core:runtime"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"

SpriteHandle :: distinct dp.Handle

Sprite :: struct {
	pos, size: Vector2,
	src:       rl.Rectangle,
	texture:   TextureHandle,
	tint:      Color,
	visible:   bool,
	zIndex:    f32,
}

Entity :: struct {
	pos:     Vector2,
	size:    Vector2,
	color:   Color,
	visible: bool,
	texture: TextureHandle,
}

EntityHandle :: distinct dp.Handle

EntityPool :: dp.DataPool(128, Entity, EntityHandle)

SpritePool :: dp.DataPool(1024, Sprite, SpriteHandle)

CollisionTargets :: [dynamic]EntityHandle

Game :: struct {
	ruby:             ^mrb.State,
	ctx:              runtime.Context,

	// Systems
	assets:           AssetSystem,
	imui:             ImUiState,
	input:            input.FrameInput,
	rand:             rand.Rand,

	// Temp Data
	collision_evts_t: map[EntityHandle]CollisionTargets,

	// Game Data
	bg_color:         rl.Color,
	entities:         EntityPool,
	sprites:          SpritePool,
}

game_init :: proc(game: ^Game) {
	game.ctx = context
	game.rand = rand.create(1)
	game.ruby = mrb.open_allocf(mruby_odin_allocf, &game.ctx)

	game.bg_color = rl.BLACK

	cwd := os.get_current_directory()
	defer delete(cwd)
	default_asset_dir := filepath.join({cwd, "assets"})

	as_init(&game.assets, default_asset_dir)

	setup_require(game.ruby)
}

game_setup_temp :: proc(game: ^Game) {
	game.collision_evts_t = make(map[EntityHandle]CollisionTargets, 16, context.temp_allocator)
}

game_add_collision :: proc(game: ^Game, a, b: EntityHandle) {
	if !(a in game.collision_evts_t) {
		game.collision_evts_t[a] = make(CollisionTargets, 0, 8, context.temp_allocator)
	}
	if !(b in game.collision_evts_t) {
		game.collision_evts_t[b] = make(CollisionTargets, 0, 8, context.temp_allocator)
	}

	when !ODIN_DISABLE_ASSERT {
		for v in game.collision_evts_t[a] {
			assert(v != a, "Item should not collide with itself")
			assert(v != b, "An item should not collide with itself twice")
		}
		for v in game.collision_evts_t[b] {
			assert(v != b, "Item should not collide with itself")
			assert(v != a, "An item should not collide with itself twice")
		}
	}

	append(&game.collision_evts_t[a], b)
	append(&game.collision_evts_t[b], a)
}

game_deinit :: proc(game: ^Game) {
	as_deinit(&game.assets)
	mrb.close(game.ruby)
}
