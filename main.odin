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
	ruby:   ^mrb.State,
	assets: AssetSystem,
	input:  input.FrameInput,
	f:      f64,
}

game_init :: proc(game: ^Game) {
	game.ruby = mrb.open()
	asset_system_init(&game.assets)
}

game_deinit :: proc(game: ^Game) {
	asset_system_deinit(&game.assets)
	mrb.close(game.ruby)
}

mrb_frame_input_type: mrb.DataType = {"FrameInput", mrb.free}

mrb_frame_input_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	i: ^input.FrameInput = cast(^input.FrameInput)mrb.rdata_data(self)
	if (i == nil) {
		mrb.data_init(self, nil, &mrb_frame_input_type)
		i = cast(^input.FrameInput)mrb.malloc(state, size_of(input.FrameInput))
		mrb.data_init(self, i, &mrb_frame_input_type)
	}
	i.current_frame = g.input.current_frame
	i.last_frame = g.input.last_frame

	return self
}

mrb_frame_input_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	i: ^input.FrameInput = cast(^input.FrameInput)mrb.rdata_data(self)
	return mrb.int_value(state, i.current_frame.meta.frame_id)
}

mrb_frame_is_key_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()

	key_sym: mrb.Sym
	mrb.get_args(state, "n", &key_sym)

	sym_name := mrb.sym_to_string(state, key_sym)
	sym_upper, success_upper := strings.to_upper(sym_name, context.temp_allocator)

	assert(success_upper == .None, "Allocation Error")
	key, is_success := reflect.enum_from_name(input.KeyboardKey, sym_upper)

	if !is_success {
		mrb.raise(
			state,
			mrb.state_get_exception_class(state),
			fmt.ctprintf("No Key Found: :%s", sym_name),
		)
		return mrb.nil_value()
	}

	i: ^input.FrameInput = cast(^input.FrameInput)mrb.rdata_data(self)
	value := input.is_pressed(i^, key)
	return mrb.bool_value(value)
}

g: ^Game
main :: proc() {


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

	fi := mrb.define_class(g.ruby, "FrameInput", mrb.state_get_object_class(g.ruby))
	mrb.define_method(g.ruby, fi, "initialize", mrb_frame_input_init, mrb.args_none())
	mrb.define_method(g.ruby, fi, "id", mrb_frame_input_id, mrb.args_none())
	mrb.define_method_id(
		g.ruby,
		fi,
		mrb.intern_cstr(g.ruby, "key_down?"),
		mrb_frame_is_key_down,
		mrb.args_req(1),
	)


	rl.SetTargetFPS(10)

	for !rl.WindowShouldClose() {
		input.update_input(&g.input)
		rl.BeginDrawing()

		defer rl.EndDrawing()

		mrb.load_string(g.ruby, code.code)
		if mrb.state_get_exc(g.ruby) != nil {
			mrb.print_error(g.ruby)
		}
		assert(mrb.state_get_exc(g.ruby) == nil, "There should be no exceptions")
	}
}
