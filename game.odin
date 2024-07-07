package main

import "base:runtime"

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:path/filepath"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"
import rb "./ring_buffer"

ActiveSoundHandle :: distinct dp.Handle

SpriteHandle :: distinct dp.Handle

SpriteType :: enum {
	Static,
	Dynamic,
}

Sprite :: struct {
	pos, size:          Vector2,
	texture:            TextureHandle,
	tint:               Color,
	type:               SpriteType,
	visible:            bool,
	z_offset, parallax: f32,
}

RevealSpot :: struct {
	pos:      Vector2,
	rotation: f32,
	texture:  rl.Texture2D,
}

Collider :: struct {
	pos:  Vector2,
	size: Vector2,
}

ColliderHandle :: distinct dp.Handle
CameraHandle :: distinct dp.Handle

ColliderPool :: dp.DataPool(128, Collider, ColliderHandle)
SpritePool :: dp.DataPool(1024, Sprite, SpriteHandle)
ActiveSoundPool :: dp.DataPool(32, rl.Sound, ActiveSoundHandle)
RevealRing :: rb.RingBuffer(256, RevealSpot)
CameraPool :: dp.DataPool(8, rl.Camera2D, CameraHandle)

CollisionTargets :: [dynamic]ColliderHandle

Game :: struct {
	ruby:             ^mrb.State,
	ctx:              runtime.Context,

	// Systems
	assets:           AssetSystem,
	imui:             ImUiState,
	input:            input.FrameInput,
	debug:            bool,
	should_exit:      bool,

	// Temp Data
	collision_evts_t: map[ColliderHandle]CollisionTargets,

	// Game Data
	camera:           CameraHandle,
	bg_color:         rl.Color,
	colliders:        ColliderPool,
	active_sounds:    ActiveSoundPool,
	sprites:          SpritePool,
	cameras:          CameraPool,
	reveal_spots:     RevealRing,
}

game_init :: proc(game: ^Game) {
	game.ctx = context
	rand.reset(1)
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

game_get_camera :: proc(game: ^Game) -> rl.Camera2D {
	if game.camera == 0 {
		width, height := input.frame_query_dimensions(game.input)
		camera: rl.Camera2D
		camera.zoom = 1
		return camera
	}
	camera, success := dp.get(&game.cameras, game.camera)
	assert(success, "Camera could not be found")
	return camera
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

game_parallax_offset :: proc(game: ^Game, parallax: f32) -> Vector2 {
	camera := game_get_camera(game)
	camera_pos := rl.GetScreenToWorld2D(camera.offset, camera)
	return camera_pos * parallax
}
