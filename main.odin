package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:reflect"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"

Vector2 :: rl.Vector2
Color :: rl.Color

debug_print_mrb_obj :: proc(game: ^Game) {
	fmt.println("Live Objects", mrb.gc_get_live(game.ruby), "State", mrb.gc_get_state(game.ruby))
	fmt.println(
		"Threshold",
		mrb.gc_get_threshold(game.ruby),
		"Live After:",
		mrb.gc_get_live_after_mark(game.ruby),
	)
}

mruby_odin_allocf :: proc "c" (
	state: ^mrb.State,
	ptr: rawptr,
	size: uint,
	user_data: rawptr,
) -> rawptr {
	ctx := transmute(^runtime.Context)user_data
	context = ctx^
	ptr_as_num := transmute(uint)ptr

	if size == 0 && ptr == nil {
		return nil
	}
	if ptr == nil {
		n_ptr, err := mem.alloc(cast(int)size)
		assert(err == .None, "Allocation Error")
		ptr_as_num := transmute(uint)n_ptr
		return n_ptr
	}
	if size == 0 {
		mem.free(ptr)
		return nil
	}

	info := mem.query_info(ptr, context.allocator)
	old_size, ok := info.size.(int)
	assert(ok, "Cannot resize if we didn't track the old size")
	n_ptr, err := mem.resize(ptr, old_size, cast(int)size)
	assert(err == .None, "Allocation Error")

	return n_ptr
}

MrubyCtx :: struct {
	ctx: runtime.Context,
}

reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> (err: bool) {
	for _, value in a.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
		err = true
	}
	mem.tracking_allocator_clear(a)
	return
}

track_bad_free_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> (err: bool) {
	for b in a.bad_free_array {
		fmt.println("Bad Free at: %v", b.location)
		err = true
	}
	return
}

TargetFPS :: 90

game_run_code :: proc(game: ^Game, handle: RubyCodeHandle, loc := #caller_location) {
	code, found := as_find_ruby(&game.assets, handle)
	assert(found, "Ruby Code not found")
	v := mrb.load_string(g.ruby, code.code)
	as_update_ruby_runtume(&game.assets, handle)

	if mrb.state_get_exc(g.ruby) != nil {
		mrb.print_backtrace(g.ruby)
	}
	assert(mrb.state_get_exc(g.ruby) == nil, "There should be no exceptions")
}

game_ctx: runtime.Context

game_check_collisions :: proc(game: ^Game) {
	iter_a := dp.new_iter(&game.colliders)
	for entity_a, handle_a in dp.iter_next(&iter_a) {
		iter_b := dp.new_iter_start_at(&game.colliders, handle_a)
		for entity_b, handle_b in dp.iter_next(&iter_b) {
			if handle_a == handle_b {
				continue
			}
			rect_a := Rectangle{entity_a.pos, entity_a.size}
			rect_b := Rectangle{entity_b.pos, entity_b.size}

			collide := shape_are_rects_colliding_aabb(rect_a, rect_b)
			if !collide {
				continue
			}
			game_add_collision(game, handle_a, handle_b)
		}
	}
}

g: ^Game
main :: proc() {
	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	defer mem.tracking_allocator_destroy(&tracking_allocator)

	context.allocator = mem.tracking_allocator(&tracking_allocator)
	defer reset_tracking_allocator(&tracking_allocator)

	game_ctx = context

	g = new(Game)
	defer free(g)

	game_init(g)
	defer game_deinit(g)

	game_load_mruby_raylib(g)

	tick_handle, tick_loaded := as_load_ruby(&g.assets, "rb/tick.rb")
	assert(tick_loaded, "`tick.rb` is required")

	rl.InitWindow(1280, 800, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	rl.SetTargetFPS(TargetFPS)

	for !rl.WindowShouldClose() {
		defer {
			is_bad := track_bad_free_tracking_allocator(&tracking_allocator)
			assert(!is_bad, "Double Free issue")
		}
		defer free_all(context.temp_allocator)
		defer mrb.incremental_gc(g.ruby)
		defer game_handle_sounds(g)

		imui_beign(&g.imui)

		game_setup_temp(g)

		input.update_input(&g.input)
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(g.bg_color)

		game_check_collisions(g)
		game_run_code(g, tick_handle)

		sprt_iter := dp.new_iter(&g.sprites)
		for spr in dp.iter_next(&sprt_iter) {
			if !spr.visible {continue}
			dest: rl.Rectangle = {spr.pos.x, spr.pos.y, spr.size.x, spr.size.y}
			asset, success := as_get_texture(&g.assets, spr.texture)
			assert(success, "We should always have a texture here")
			rl.DrawTexturePro(asset.texture, asset.src, dest, spr.size * 0.5, 0, spr.tint)
		}
		game_debug_draw(g)

		imui_draw(&g.imui)

		// Check for asset change every second or so
		if input.frame_query_id(g.input) % TargetFPS == 0 {
			as_check(&g.assets)
		}
	}
}
