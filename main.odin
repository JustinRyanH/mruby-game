package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:reflect"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import "./input"
import mrb "./mruby"
import "./utils"

AssetError :: enum {
	NoAssetError,
}


RubyCodeHandle :: distinct u64

ruby_code_handle :: proc(str: string) -> RubyCodeHandle {
	return cast(RubyCodeHandle)utils.generate_u64_from_string(str)

}

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
	handle := ruby_code_handle(file)
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

asset_system_find_ruby :: proc(as: ^AssetSystem, handle: RubyCodeHandle) -> (RubyCode, bool) {
	return as.ruby[handle]
}

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
	code, found := asset_system_find_ruby(&g.assets, ruby_code_handle("foo.rb"))
	assert(found, "Ruby Code 'foo.rb' not found")


	rl.InitWindow(1280, 800, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()


	rl.SetTargetFPS(90)


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
		v := mrb.load_string(g.ruby, code.code)
		defer mrb.gc_mark_value(g.ruby, v)

		if mrb.state_get_exc(g.ruby) != nil {
			mrb.print_error(g.ruby)
		}
		assert(mrb.state_get_exc(g.ruby) == nil, "There should be no exceptions")
	}
}
