package main

import "core:fmt"
import "core:math"
import "core:reflect"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"

mrb_frame_input_type: mrb.DataType = {"FrameInput", mrb.free}
mrb_entity_handle_type: mrb.DataType = {"Entity", mrb.free}
mrb_vector_handle_type: mrb.DataType = {"Vector", mrb.free}
mrb_color_handle_type: mrb.DataType = {"Color", mrb.free}

EngineRClass :: struct {
	entity_class: ^mrb.RClass,
	vector_class: ^mrb.RClass,
	color_class:  ^mrb.RClass,
}

engine_classes: EngineRClass

game_load_mruby_raylib :: proc(game: ^Game) {
	st := game.ruby
	logger := mrb.define_class(st, "Log", mrb.state_get_object_class(st))
	mrb.define_class_method(st, logger, "info", logger_info, mrb.args_req(1))
	mrb.define_class_method(st, logger, "error", logger_error, mrb.args_req(1))
	mrb.define_class_method(st, logger, "fatal", logger_fatal, mrb.args_req(1))
	mrb.define_class_method(st, logger, "warning", logger_warning, mrb.args_req(1))

	setup_game_class(st)
	setup_input(st)
	setup_entity_class(st)
	setup_vector_class(st)
	setup_color_class(st)
}

setup_color_class :: proc(st: ^mrb.State) {
	color_class := mrb.define_class(st, "Color", mrb.state_get_object_class(st))
	mrb.set_data_type(color_class, .CData)
	mrb.define_method(st, color_class, "initialize", color_init, mrb.args_req(4))
	mrb.define_method(st, color_class, "red", color_get_r, mrb.args_none())
	mrb.define_method(st, color_class, "r", color_get_r, mrb.args_none())
	mrb.define_method(st, color_class, "blue", color_get_b, mrb.args_none())
	mrb.define_method(st, color_class, "b", color_get_b, mrb.args_none())
	mrb.define_method(st, color_class, "green", color_get_g, mrb.args_none())
	mrb.define_method(st, color_class, "g", color_get_g, mrb.args_none())
	mrb.define_method(st, color_class, "alpha", color_get_a, mrb.args_none())
	mrb.define_method(st, color_class, "a", color_get_a, mrb.args_none())

	for pallet in ColorPallet {
		as_str, success := reflect.enum_name_from_value(pallet)
		assert(success, "Somehow the name reflection failed")
		snake_pallet := strings.to_snake_case(as_str, context.temp_allocator)
		mrb.define_class_method_id(
			st,
			color_class,
			mrb.sym_from_string(st, snake_pallet),
			color_from_pallet,
			mrb.args_none(),
		)
	}
	engine_classes.color_class = color_class
}

setup_vector_class :: proc(st: ^mrb.State) {
	vector_class := mrb.define_class(st, "Vector", mrb.state_get_object_class(st))
	mrb.set_data_type(vector_class, .CData)
	mrb.define_method(st, vector_class, "initialize", vector_init, mrb.args_req(2))
	mrb.define_method(st, vector_class, "x", vector_get_x, mrb.args_none())
	mrb.define_method(st, vector_class, "x=", vector_set_x, mrb.args_req(1))
	mrb.define_method(st, vector_class, "y", vector_get_y, mrb.args_none())
	mrb.define_method(st, vector_class, "y=", vector_set_y, mrb.args_req(1))
	engine_classes.vector_class = vector_class
}

setup_entity_class :: proc(st: ^mrb.State) {
	entity_class := mrb.define_class(st, "Entity", mrb.state_get_object_class(st))
	mrb.set_data_type(entity_class, .CData)
	mrb.define_method(st, entity_class, "initialize", entity_init, mrb.args_req(1))
	mrb.define_method(st, entity_class, "valid?", entity_valid, mrb.args_none())
	mrb.define_method(st, entity_class, "x", entity_get_x, mrb.args_none())
	mrb.define_method(st, entity_class, "x=", entity_set_x, mrb.args_req(1))
	mrb.define_method(st, entity_class, "y", entity_get_y, mrb.args_none())
	mrb.define_method(st, entity_class, "y=", entity_set_y, mrb.args_req(1))
	engine_classes.entity_class = entity_class
}

setup_game_class :: proc(st: ^mrb.State) {
	game_class := mrb.define_class(st, "Game", mrb.state_get_object_class(st))
	mrb.define_class_method(
		st,
		game_class,
		"player_entity",
		game_get_player_entity,
		mrb.args_none(),
	)
}

setup_input :: proc(st: ^mrb.State) {
	fi := mrb.define_class(st, "FrameInput", mrb.state_get_object_class(st))
	mrb.define_class_method(st, fi, "delta_time", frame_input_dt, mrb.args_none())
	mrb.define_class_method(st, fi, "id", frame_input_id, mrb.args_none())
	mrb.define_class_method(st, fi, "key_down?", frame_input_is_down, mrb.args_req(1))
	mrb.define_class_method(st, fi, "key_was_down?", frame_input_was_down, mrb.args_req(1))
}


//////////////////////////////
//// FrameInput
//////////////////////////////
@(private = "file")
frame_input_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
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
frame_input_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	i := g.input
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

	value := input.is_pressed(g.input, key)
	return mrb.bool_value(value)
}

@(private = "file")
frame_input_dt :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	dt := input.frame_query_delta(g.input)
	return mrb.float_value(state, cast(f64)dt)
}


@(private = "file")
frame_input_was_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()

	key, success := sym_to_keyboard_key(state)
	if !success {
		return mrb.nil_value()
	}

	value := input.was_just_released(g.input, key)
	return mrb.bool_value(value)
}

//////////////////////////////
//// Game
//////////////////////////////
@(private = "file")
game_get_player_entity :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	id := mrb.int_value(state, cast(int)g.player)
	collection: []mrb.Value = {id}
	return mrb.obj_new(state, engine_classes.entity_class, 1, raw_data(collection[:]))
}


//////////////////////////////
//// Logger
//////////////////////////////
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

//////////////////////////////
//// Entity
//////////////////////////////
@(private = "file")
entity_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	entity_id: int
	mrb.get_args(state, "i", &entity_id)

	i := mrb.get_data_from_value(EntityHandle, self)

	if (i == nil) {
		mrb.data_init(self, nil, &mrb_entity_handle_type)
		v := mrb.malloc(state, size_of(EntityHandle))
		i = cast(^EntityHandle)v
		mrb.data_init(self, i, &mrb_entity_handle_type)
	}
	i^ = cast(EntityHandle)entity_id

	return self
}
@(private = "file")
entity_valid :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx

	handle := mrb.get_data_from_value(EntityHandle, self)
	success := dp.valid(&g.entities, handle^)
	return mrb.bool_value(success)
}

@(private = "file")
entity_get_x :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx

	i := mrb.get_data_from_value(EntityHandle, self)
	entity, success := dp.get(&g.entities, i^)
	if !success {
		mrb.raise_exception(state, "Failed to access Entity")
	}
	return mrb.float_value(state, cast(f64)entity.pos.x)
}

@(private = "file")
entity_set_x :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx
	new_x: f64
	mrb.get_args(state, "f", &new_x)

	i := mrb.get_data_from_value(EntityHandle, self)
	entity := dp.get_ptr(&g.entities, i^)
	if entity == nil {
		mrb.raise_exception(state, "Failed to access Entity")
	}
	entity.pos.x = cast(f32)new_x
	return mrb.nil_value()
}


@(private = "file")
entity_get_y :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx

	i := mrb.get_data_from_value(EntityHandle, self)
	entity, success := dp.get(&g.entities, i^)
	if !success {
		mrb.raise_exception(state, "Failed to access Entity")
	}
	return mrb.float_value(state, cast(f64)entity.pos.y)
}

@(private = "file")
entity_set_y :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx

	new_y: f64
	mrb.get_args(state, "f", &new_y)

	i := mrb.get_data_from_value(EntityHandle, self)
	entity := dp.get_ptr(&g.entities, i^)
	if entity == nil {
		mrb.raise_exception(state, "Failed to access Entity")
	}
	entity.pos.y = cast(f32)new_y
	return mrb.nil_value()
}

@(private = "file")
vector_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	inc_x: f64
	inc_y: f64
	mrb.get_args(state, "ff", &inc_x, &inc_y)

	v := mrb.get_data_from_value(rl.Vector2, self)
	if (v == nil) {
		mrb.data_init(self, nil, &mrb_entity_handle_type)
		v = cast(^rl.Vector2)mrb.malloc(state, size_of(rl.Vector2))
		mrb.data_init(self, v, &mrb_entity_handle_type)
	}
	v.x = cast(f32)inc_x
	v.y = cast(f32)inc_y
	return self
}

//////////////////////////////
//// Vector
//////////////////////////////
@(private = "file")
vector_get_x :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Vector2, self)
	return mrb.float_value(state, cast(f64)v.x)
}

@(private = "file")
vector_set_x :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	new_x: f64
	mrb.get_args(state, "f", &new_x)

	v := mrb.get_data_from_value(rl.Vector2, self)
	v.x = cast(f32)new_x
	return mrb.nil_value()
}


@(private = "file")
vector_get_y :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Vector2, self)
	return mrb.float_value(state, cast(f64)v.y)
}

@(private = "file")
vector_set_y :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx

	new_y: f64
	mrb.get_args(state, "f", &new_y)

	v := mrb.get_data_from_value(rl.Vector2, self)
	v.y = cast(f32)new_y
	return mrb.nil_value()
}

//////////////////////////////
//// Color
//////////////////////////////
@(private = "file")
color_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	r, b, g, a: int
	mrb.get_args(state, "iiii", &r, &b, &g, &a)

	v: ^rl.Color = mrb.get_data_from_value(rl.Color, self)
	if (v == nil) {
		mrb.data_init(self, nil, &mrb_color_handle_type)
		v = cast(^rl.Color)mrb.malloc(state, size_of(rl.Color))
		mrb.data_init(self, v, &mrb_color_handle_type)
	}
	v.r = cast(u8)math.clamp(r, 0, 255)
	v.b = cast(u8)math.clamp(b, 0, 255)
	v.g = cast(u8)math.clamp(g, 0, 255)
	v.a = cast(u8)math.clamp(a, 0, 255)
	return self
}

@(private = "file")
color_get_r :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Color, self)
	return mrb.int_value(state, cast(int)v.r)
}

@(private = "file")
color_get_b :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Color, self)
	return mrb.int_value(state, cast(int)v.b)
}

@(private = "file")
color_get_g :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Color, self)
	return mrb.int_value(state, cast(int)v.g)
}

@(private = "file")
color_get_a :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Color, self)
	return mrb.int_value(state, cast(int)v.a)
}

@(private = "file")
color_from_pallet :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = game_ctx
	method_name := mrb.get_mid(state)
	str := mrb.sym_to_string(state, method_name)

	pallet, success := color_pallet_from_snake(str)
	assert(success, fmt.tprintf("Pallet method is not correct: %s", str))

	color := pallet_to_color[pallet]
	colors: [4]mrb.Value

	for val, idx in color {colors[idx] = mrb.int_value(state, cast(int)val)}

	return mrb.obj_new(state, engine_classes.color_class, len(colors), raw_data(colors[:]))
}
