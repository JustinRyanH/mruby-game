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

ActiveSoundHandle :: distinct dp.Handle

SpriteHandle :: distinct dp.Handle

Sprite :: struct {
	pos, size: Vector2,
	texture:   TextureHandle,
	tint:      Color,
	visible:   bool,
	z_index:   f32,
}

Collider :: struct {
	pos:  Vector2,
	size: Vector2,
}

ColliderHandle :: distinct dp.Handle

ColliderPool :: dp.DataPool(128, Collider, ColliderHandle)
SpritePool :: dp.DataPool(1024, Sprite, SpriteHandle)
ActiveSoundPool :: dp.DataPool(32, rl.Sound, ActiveSoundHandle)

CollisionTargets :: [dynamic]ColliderHandle

Game :: struct {
	ruby:             ^mrb.State,
	ctx:              runtime.Context,

	// Systems
	assets:           AssetSystem,
	imui:             ImUiState,
	input:            input.FrameInput,
	rand:             rand.Rand,
	debug:            bool,
	should_exit:      bool,

	// Temp Data
	collision_evts_t: map[ColliderHandle]CollisionTargets,

	// Game Data
	camera:           ^rl.Camera2D,
	bg_color:         rl.Color,
	colliders:        ColliderPool,
	active_sounds:    ActiveSoundPool,
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
	game.collision_evts_t = make(map[ColliderHandle]CollisionTargets, 16, context.temp_allocator)
}

game_add_collision :: proc(game: ^Game, a, b: ColliderHandle) {
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


game_debug_draw :: proc(game: ^Game) {
	if !g.debug {
		return
	}
	cldr_iter := dp.new_iter(&g.colliders)
	for clr in dp.iter_next(&cldr_iter) {
		pos := clr.pos - clr.size * 0.5
		rect := rl.Rectangle{pos.x, pos.y, clr.size.x, clr.size.y}
		rl.DrawRectangleLinesEx(rect, 2.0, rl.GREEN)
	}
}

game_alias_sound :: proc(game: ^Game, sh: SoundHandle) -> (ActiveSoundHandle, rl.Sound) {
	og_sound, sound_exists := as_get_sound(&g.assets, sh)
	assert(sound_exists, "Requested Sound does not exists")

	alias := rl.LoadSoundAlias(og_sound.sound)
	ah, success := dp.add(&game.active_sounds, alias)
	assert(success, "Failed to create a Sound Alias")


	return ah, alias
}


game_handle_sounds :: proc(game: ^Game) {
	sound_iter := dp.new_iter(&game.active_sounds)
	for sound, hndle in dp.iter_next(&sound_iter) {
		if !rl.IsSoundPlaying(sound) {
			dp.remove(&game.active_sounds, hndle)
		}
	}
}
