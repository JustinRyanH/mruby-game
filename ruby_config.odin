package main

import "core:fmt"
import "core:reflect"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import "./input"
import mrb "./mruby"


game_load_mruby_raylib :: proc(game: ^Game) {
	logger := mrb.define_class(g.ruby, "Log", mrb.state_get_object_class(g.ruby))
	mrb.define_class_method(g.ruby, logger, "info", logger_info, mrb.args_req(1))
	mrb.define_class_method(g.ruby, logger, "error", logger_error, mrb.args_req(1))
	mrb.define_class_method(g.ruby, logger, "fatal", logger_fatal, mrb.args_req(1))
	mrb.define_class_method(g.ruby, logger, "warning", logger_warning, mrb.args_req(1))

	game_class := mrb.define_class(g.ruby, "Game", mrb.state_get_object_class(g.ruby))
	mrb.define_class_method(
		g.ruby,
		game_class,
		"player_entity",
		game_get_player_entity,
		mrb.args_none(),
	)

	setup_input(game)
}

game_get_player_entity :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return mrb.nil_value()
}

setup_input :: proc(game: ^Game) {
	fi := mrb.define_class(g.ruby, "FrameInput", mrb.state_get_object_class(g.ruby))
	mrb.set_data_type(fi, .CData)
	mrb.define_method(g.ruby, fi, "initialize", frame_input_init, mrb.args_none())
	mrb.define_method(g.ruby, fi, "delta_time", frame_input_dt, mrb.args_none())
	mrb.define_method(g.ruby, fi, "id", frmae_input_id, mrb.args_none())
	mrb.define_method_id(
		g.ruby,
		fi,
		mrb.intern_cstr(g.ruby, "key_down?"),
		frame_input_is_down,
		mrb.args_req(1),
	)
	mrb.define_method_id(
		g.ruby,
		fi,
		mrb.intern_cstr(g.ruby, "key_was_down?"),
		frame_input_was_down,
		mrb.args_req(1),
	)
}

mrb_frame_input_type: mrb.DataType = {"FrameInput", mrb.free}

@(private = "file")
frame_input_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	i := mrb.get_data_from_value(input.FrameInput, self)

	if (i == nil) {
		mrb.data_init(self, nil, &mrb_frame_input_type)
		v := mrb.malloc(state, size_of(input.FrameInput))
		i = cast(^input.FrameInput)v
		mrb.data_init(self, i, &mrb_frame_input_type)
	}
	i.current_frame = g.input.current_frame
	i.last_frame = g.input.last_frame

	return self
}

@(private = "file")
frmae_input_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	i: ^input.FrameInput = cast(^input.FrameInput)mrb.rdata_data(self)
	return mrb.int_value(state, i.current_frame.meta.frame_id)
}

@(private = "file")
sym_to_keyboard_key :: proc(state: ^mrb.State) -> (key: input.KeyboardKey, success: bool) {
	key_sym: mrb.Sym
	mrb.get_args(state, "n", &key_sym)

	sym_name := mrb.sym_to_string(state, key_sym)
	sym_upper, upper_err := strings.to_upper(sym_name, context.temp_allocator)
	if upper_err != .None {
		mrb.raise_exception(state, "Allocation Error: %v", upper_err)
		return
	}

	key, success = reflect.enum_from_name(input.KeyboardKey, sym_upper)

	if !success {
		mrb.raise_exception(state, "No Key found: :%s", sym_name)
		return
	}

	return
}

@(private = "file")
frame_input_is_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()

	key, success := sym_to_keyboard_key(state)
	if !success {
		return mrb.nil_value()
	}

	i := mrb.get_data_from_value(input.FrameInput, self)
	value := input.is_pressed(i^, key)
	return mrb.bool_value(value)
}

@(private = "file")
frame_input_dt :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	i := mrb.get_data_from_value(input.FrameInput, self)
	dt := input.frame_query_delta(i^)

	return mrb.float_value(state, cast(f64)dt)
}


@(private = "file")
frame_input_was_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()

	key, success := sym_to_keyboard_key(state)
	if !success {
		return mrb.nil_value()
	}

	i := mrb.get_data_from_value(input.FrameInput, self)
	value := input.was_just_released(i^, key)
	return mrb.bool_value(value)
}


@(private = "file")
logger_info :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.INFO, cstr)
	return mrb.nil_value()
}

@(private = "file")
logger_error :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.ERROR, cstr)
	return mrb.nil_value()
}

@(private = "file")
logger_warning :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.WARNING, cstr)
	return mrb.nil_value()
}

@(private = "file")
logger_fatal :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.FATAL, cstr)
	return mrb.nil_value()
}
