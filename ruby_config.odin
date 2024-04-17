package main

import "core:runtime"

import rl "vendor:raylib"

import mrb "./mruby"


logger_info :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.INFO, cstr)
	return mrb.nil_value()
}

logger_error :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.ERROR, cstr)
	return mrb.nil_value()
}

logger_warning :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.WARNING, cstr)
	return mrb.nil_value()
}


logger_fatal :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.FATAL, cstr)
	return mrb.nil_value()
}


game_load_mruby_raylib :: proc(game: ^Game) {
	logger := mrb.define_class(g.ruby, "Log", mrb.state_get_object_class(g.ruby))
	mrb.define_class_method(g.ruby, logger, "info", logger_info, mrb.args_req(1))
	mrb.define_class_method(g.ruby, logger, "error", logger_error, mrb.args_req(1))
	mrb.define_class_method(g.ruby, logger, "fatal", logger_fatal, mrb.args_req(1))
	mrb.define_class_method(g.ruby, logger, "warning", logger_warning, mrb.args_req(1))
}
