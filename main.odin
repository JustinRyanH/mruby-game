package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:reflect"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import "./input"
import mrb "./mruby"

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
	mruby_ctx := transmute(^MrubyCtx)user_data
	context = mruby_ctx.ctx
	ptr_as_num := transmute(uint)ptr

	if size == 0 {
		mem.free(ptr)
		if ptr_as_num in mruby_ctx.alloc_ref {
			delete_key(&mruby_ctx.alloc_ref, ptr_as_num)
		}
		return nil
	}
	if ptr == nil {
		n_ptr, err := mem.alloc(cast(int)size)
		assert(err == .None, "Allocation Error")
		ptr_as_num := transmute(uint)n_ptr
		mruby_ctx.alloc_ref[ptr_as_num] = size
		return n_ptr
	}

	old_size := mruby_ctx.alloc_ref[ptr_as_num]
	n_ptr, err := mem.resize(ptr, cast(int)old_size, cast(int)size)
	assert(err == .None, "Allocation Error")

	return n_ptr
}

MrubyCtx :: struct {
	ctx:       runtime.Context,
	alloc_ref: map[uint]uint,
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

g: ^Game
main :: proc() {

	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	defer mem.tracking_allocator_destroy(&tracking_allocator)

	context.allocator = mem.tracking_allocator(&tracking_allocator)
	defer reset_tracking_allocator(&tracking_allocator)

	g = new(Game)
	defer free(g)

	game_init(g)
	defer game_deinit(g)

	game_load_mruby_raylib(g)

	asset_system_load_ruby(&g.assets, "foo.rb")

	rl.InitWindow(1280, 800, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()

	rl.SetTargetFPS(TargetFPS)

	for !rl.WindowShouldClose() {
		defer {
			is_bad := track_bad_free_tracking_allocator(&tracking_allocator)
			assert(!is_bad, "Double Free issue")
		}
		defer free_all(context.temp_allocator)
		defer mrb.incremental_gc(g.ruby)

		input.update_input(&g.input)
		rl.BeginDrawing()
		defer rl.EndDrawing()

		code, found := asset_system_find_ruby(&g.assets, ruby_code_handle("foo.rb"))
		assert(found, "Ruby Code 'foo.rb' not found")
		v := mrb.load_string(g.ruby, code.code)
		defer mrb.gc_mark_value(g.ruby, v)

		if mrb.state_get_exc(g.ruby) != nil {
			mrb.print_error(g.ruby)
		}
		assert(mrb.state_get_exc(g.ruby) == nil, "There should be no exceptions")

		// Check for asset change every second or so
		if input.frame_query_id(g.input) % TargetFPS == 0 {
			asset_system_check(&g.assets)
		}
	}
}
