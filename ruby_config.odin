package main

import "base:runtime"

import "core:fmt"
import "core:math/ease"
import math "core:math/linalg"
import "core:math/rand"
import "core:reflect"
import "core:strings"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"
import rp "./rect_pack"
import "./utils"


load_context :: proc "contextless" (state: ^mrb.State) -> runtime.Context {
	ctx := transmute(^runtime.Context)mrb.state_alloc_ud(state)
	return ctx^
}


// This uses reflects to lfofad in the kwargs.
load_kwargs :: proc($T: typeid, state: ^mrb.State, args: ^T) {
	names := reflect.struct_field_names(T)
	num_of_args := len(names)
	syms := make([]mrb.Sym, len(names), context.temp_allocator)
	for name, i in names {
		syms[i] = mrb.sym_from_string(state, name)
	}

	kwargs: mrb.Kwargs
	kwargs.num = num_of_args
	kwargs.table = raw_data(syms[:])
	kwargs.values = transmute([^]mrb.Value)args

	mrb.get_args(state, ":", &kwargs)
}

init_cdata :: proc "contextless" (
	$T: typeid,
	state: ^mrb.State,
	value: mrb.Value,
	dt: ^mrb.DataType,
) -> ^T {
	v_data := mrb.get_data_from_value(T, value)


	if (v_data == nil) {
		mrb.data_init(value, nil, dt)
		v_data = cast(^T)mrb.malloc(state, size_of(T))
		mrb.data_init(value, v_data, dt)
	}
	return v_data
}

get_curent_game :: proc "contextless" (state: ^mrb.State) -> mrb.Value {
	context = load_context(state)

	game_class := mrb.class_get(g.ruby, "Game")
	assert(game_class != nil, "Game class must be defined")
	v := mrb.obj_value(game_class)
	empty := []mrb.Value{}

	id := mrb.sym_from_string(g.ruby, "current")
	current := mrb.funcall_argv(g.ruby, v, id, 0, raw_data(empty))
	assert(mrb.object_p(current), "Expected this to be instance of Class")
	return current
}

mrb_camera_tpye: mrb.DataType = {"Camera", mrb.free}
mrb_collider_type: mrb.DataType = {"Collider", mrb.free}
mrb_color_type: mrb.DataType = {"Color", mrb.free}
mrb_font_handle_type: mrb.DataType = {"Font", mrb.free}
mrb_frame_input_type: mrb.DataType = {"FrameInput", mrb.free}
mrb_sprite_type: mrb.DataType = {"Sprite", mrb.free}
mrb_vector_type: mrb.DataType = {"Vector", mrb.free}

EngineRClass :: struct {
	as:            ^mrb.RClass,
	camera:        ^mrb.RClass,
	collider:      ^mrb.RClass,
	color:         ^mrb.RClass,
	draw_module:   ^mrb.RClass,
	engine:        ^mrb.RClass,
	font_asset:    ^mrb.RClass,
	frame:         ^mrb.RClass,
	rect_pack:     ^mrb.RClass,
	screen:        ^mrb.RClass,
	set:           ^mrb.RClass,
	sound:         ^mrb.RClass,
	sprite:        ^mrb.RClass,
	texture_asset: ^mrb.RClass,
	vector:        ^mrb.RClass,
}

engine_classes: EngineRClass

game_load_mruby_raylib :: proc(game: ^Game) {
	st := game.ruby

	engine_classes.set = mrb.class_get(st, "Set")
	setup_easing(st)
	setup_engine(st)
	setup_assets(st)
	setup_draw(st)
	setup_input(st)
	setup_log_class(st)
	setup_entity_class(st)
	setup_sprite_class(st)
	setup_camera_class(st)
	setup_screen_class(st)
	setup_vector_class(st)
	setup_color_class(st)
	setup_rect_pack_class(st)
}

setup_easing :: proc(st: ^mrb.State) {
	mrb.define_method(st, mrb.state_get_integer_class(st), "ease", int_ease, mrb.args_req(1))
	mrb.define_method(st, mrb.state_get_float_class(st), "ease", float_ease, mrb.args_req(1))

}

float_ease :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	ease_type_v: mrb.Sym
	mrb.get_args(state, "n", &ease_type_v)

	sym_name := mrb.sym_to_string(state, ease_type_v)
	ease_string, ada_err := strings.to_ada_case(sym_name, context.temp_allocator)
	assert(ada_err == .None, "Failed to convert symbol to AdaCase")
	ease_type, success := reflect.enum_from_name(ease.Ease, ease_string)
	assert(success, fmt.tprintf("Failed to convert %s to an ease", ease_string))

	value := mrb.as_float(state, self)
	new_value := ease.ease(ease_type, value)


	return mrb.float_value(state, new_value)
}

int_ease :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return self
}


setup_log_class :: proc(st: ^mrb.State) {
	logger := mrb.define_class(st, "Log", mrb.state_get_object_class(st))
	mrb.define_class_method(st, logger, "info", logger_info, mrb.args_req(1))
	mrb.define_class_method(st, logger, "error", logger_error, mrb.args_req(1))
	mrb.define_class_method(st, logger, "fatal", logger_fatal, mrb.args_req(1))
	mrb.define_class_method(st, logger, "warn", logger_warning, mrb.args_req(1))
}

setup_input :: proc(st: ^mrb.State) {
	frame_class := mrb.define_class(st, "FrameInput", mrb.state_get_object_class(st))
	mrb.define_class_method(st, frame_class, "delta_time", frame_input_dt, mrb.args_none())
	mrb.define_class_method(st, frame_class, "id", frame_input_id, mrb.args_none())
	mrb.define_class_method(st, frame_class, "key_down?", frame_input_is_down, mrb.args_req(1))
	mrb.define_class_method(
		st,
		frame_class,
		"key_just_pressed?",
		frame_input_just_pressed,
		mrb.args_req(1),
	)
	mrb.define_class_method(
		st,
		frame_class,
		"key_was_down?",
		frame_input_was_down,
		mrb.args_req(1),
	)
	mrb.define_class_method(st, frame_class, "screen", frame_input_screen, mrb.args_none())
	mrb.define_class_method(
		st,
		frame_class,
		"screen_size",
		frame_input_screen_size,
		mrb.args_none(),
	)
	mrb.define_class_method(st, frame_class, "mouse_pos", frame_input_mouse_pos, mrb.args_none())
	mrb.define_class_method(
		st,
		frame_class,
		"mouse_down?",
		frame_input_mouse_is_down,
		mrb.args_req(1),
	)
	mrb.define_class_method(
		st,
		frame_class,
		"mouse_just_pressed?",
		frame_input_mouse_just_pressed,
		mrb.args_req(1),
	)
	mrb.define_class_method(
		st,
		frame_class,
		"mouse_was_down?",
		frame_input_mouse_was_down,
		mrb.args_req(1),
	)
	mrb.define_class_method(
		st,
		frame_class,
		"random_float",
		frame_input_random_float,
		mrb.args_req(1),
	)
	mrb.define_class_method(st, frame_class, "random_int", frame_input_random_int, mrb.args_req(1))


	engine_classes.frame = frame_class
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
	return mrb.int_value(state, cast(mrb.Int)i.current_frame.meta.frame_id)
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
sym_to_mouse_button :: proc(state: ^mrb.State) -> (btn: input.MouseButton, success: bool) {
	key_sym: mrb.Sym
	mrb.get_args(state, "n", &key_sym)

	sym_name := mrb.sym_to_string(state, key_sym)
	sym_upper, upper_err := strings.to_upper(sym_name, context.temp_allocator)
	if upper_err != .None {
		mrb.raise_exception(state, "Allocation Error: %v", upper_err)
		return
	}

	btn, success = reflect.enum_from_name(input.MouseButton, sym_upper)

	if !success {
		mrb.raise_exception(state, "No Key found: :%s", sym_name)
		return
	}

	return
}
@(private = "file")
frame_input_screen :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return mrb.obj_new(state, engine_classes.screen, 0, nil)
}

@(private = "file")
frame_input_screen_size :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	width, height := input.frame_query_dimensions(g.input)
	mrb_width, mrb_height := cast(mrb.Float)width, cast(mrb.Float)height
	return mrb.assoc_new(
		state,
		mrb.float_value(state, mrb_width),
		mrb.float_value(state, mrb_height),
	)
}


@(private = "file")
frame_input_mouse_pos :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	vector := input.mouse_position(g.input)
	return vector_obj_from_vec(state, vector)
}

@(private = "file")
frame_input_random_float :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	rng_v: mrb.Value
	mrb.get_args(state, "o", &rng_v)
	rng := mrb.range_ptr(state, rng_v)

	low, high, is_exlusive := mrb.parse_range_int(state, rng)
	// TODO: Come up with a way to do inclusive float range
	if !is_exlusive {
		mrb.raise_exception(
			state,
			"random_float must take an exclusive range. use `%d...%d` instead",
			low,
			high,
		)
	}
	v := rand.float32_range(cast(mrb.Float)low, cast(mrb.Float)high, &g.rand)

	return mrb.float_value(state, v)
}

@(private = "file")
frame_input_random_int :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	rng_v: mrb.Value
	mrb.get_args(state, "o", &rng_v)
	rng := mrb.range_ptr(state, rng_v)
	low, high, is_exlusive := mrb.parse_range_int(state, rng)

	if is_exlusive {
		if low == high {
			mrb.raise_exception(
				state,
				"Cannot do a exclusive range where both values were the same",
			)
		}

		upper := cast(i64)(high - low)
		v := cast(int)rand.int63_max(upper, &g.rand)
		return mrb.int_value(state, v + low)
	}

	// We don't do the guard here because I still want to have the RND move 
	// event if we don't get a real value
	upper := cast(i64)(high - low)
	v := cast(int)rand.int63_max(upper + 1, &g.rand)
	return mrb.int_value(state, v + low)

}


@(private = "file")
frame_input_is_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

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
	return mrb.float_value(state, cast(mrb.Float)dt)
}

@(private = "file")
frame_input_just_pressed :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	key, success := sym_to_keyboard_key(state)
	if !success {
		return mrb.nil_value()
	}

	value := input.was_just_pressed(g.input, key)
	return mrb.bool_value(value)

}


@(private = "file")
frame_input_was_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	key, success := sym_to_keyboard_key(state)
	if !success {
		return mrb.nil_value()
	}

	value := input.was_just_released(g.input, key)
	return mrb.bool_value(value)
}


@(private = "file")
frame_input_mouse_is_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	key, success := sym_to_mouse_button(state)
	if !success {
		return mrb.nil_value()
	}

	value := input.is_pressed(g.input, key)
	return mrb.bool_value(value)
}

@(private = "file")
frame_input_mouse_just_pressed :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	key, success := sym_to_mouse_button(state)
	if !success {
		return mrb.nil_value()
	}

	value := input.was_just_pressed(g.input, key)
	return mrb.bool_value(value)

}


@(private = "file")
frame_input_mouse_was_down :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	key, success := sym_to_mouse_button(state)
	if !success {
		return mrb.nil_value()
	}

	value := input.was_just_released(g.input, key)
	return mrb.bool_value(value)
}


//////////////////////////////
//// Logger
//////////////////////////////
@(private = "file")
logger_info :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.INFO, cstr)
	return mrb.nil_value()
}

@(private = "file")
logger_error :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.ERROR, cstr)
	return mrb.nil_value()
}

@(private = "file")
logger_warning :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.WARNING, cstr)
	return mrb.nil_value()
}

@(private = "file")
logger_fatal :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	cstr: cstring
	mrb.get_args(state, "z", &cstr)
	rl.TraceLog(.FATAL, cstr)
	return mrb.nil_value()
}

//////////////////////////////
//// collider
//////////////////////////////

setup_entity_class :: proc(st: ^mrb.State) {
	collider_class := mrb.define_class(st, "Collider", mrb.state_get_object_class(st))
	mrb.set_data_type(collider_class, .CData)
	mrb.define_method(st, collider_class, "initialize", collider_init, mrb.args_req(1))
	// Removes the Entity, returns true if is was destroyed,
	// return false if failed (likely because it was already destroyed)
	mrb.define_method(st, collider_class, "destroy", collider_destroy, mrb.args_none())
	mrb.define_method(st, collider_class, "id", collider_get_id, mrb.args_none())
	mrb.define_method(st, collider_class, "valid?", collider_valid, mrb.args_none())
	mrb.define_method(st, collider_class, "pos", collider_get_pos, mrb.args_none())
	mrb.define_method(st, collider_class, "pos=", collider_pos_set, mrb.args_req(1))
	mrb.define_method(st, collider_class, "size", collider_size_get, mrb.args_none())
	mrb.define_method(st, collider_class, "collisions", collider_other_collisions, mrb.args_none())
	mrb.define_class_method(st, collider_class, "create", collider_create, mrb.args_key(1, 0))

	mrb.define_alias(st, collider_class, "hash", "id")
	engine_classes.collider = collider_class
}

@(private = "file")
collider_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	collider_id: int
	mrb.get_args(state, "i", &collider_id)

	i := mrb.get_data_from_value(ColliderHandle, self)

	if (i == nil) {
		mrb.data_init(self, nil, &mrb_collider_type)
		v := mrb.malloc(state, size_of(ColliderHandle))
		i = cast(^ColliderHandle)v
		mrb.data_init(self, i, &mrb_collider_type)
	}
	i^ = cast(ColliderHandle)collider_id

	return self
}

@(private = "file")
collider_destroy :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	i := mrb.get_data_from_value(ColliderHandle, self)^
	assert(i != 0, "ColliderHandle should not be 0")

	if !dp.valid(&g.colliders, i) {
		mrb.bool_value(false)
	}
	success := dp.remove(&g.colliders, i)
	return mrb.bool_value(success)
}

@(private = "file")
collider_get_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(ColliderHandle, self)
	success := dp.valid(&g.colliders, handle^)
	if success {
		return mrb.int_value(state, cast(mrb.Int)handle^)
	}
	return mrb.nil_value()
}

@(private = "file")
collider_valid :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(ColliderHandle, self)
	success := dp.valid(&g.colliders, handle^)
	return mrb.bool_value(success)
}

@(private = "file")
collider_get_pos :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(ColliderHandle, self)

	collider, found := dp.get(&g.colliders, handle^)
	if !found {
		mrb.raise_exception(state, "Failed to access collider: %d", handle^)
	}

	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)collider.pos.x),
		mrb.float_value(state, cast(mrb.Float)collider.pos.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
collider_pos_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	new_pos: mrb.Value
	mrb.get_args(state, "o", &new_pos)
	assert(
		mrb.obj_is_kind_of(state, new_pos, engine_classes.vector),
		"Can only assign Vector to position",
	)

	pos := mrb.get_data_from_value(Vector2, new_pos)

	i := mrb.get_data_from_value(ColliderHandle, self)
	collider := dp.get_ptr(&g.colliders, i^)
	if collider == nil {
		mrb.raise_exception(state, "Failed to access collider: %d", i^)
	}
	collider.pos = pos^

	return mrb.nil_value()
}

@(private = "file")
collider_size_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(ColliderHandle, self)

	collider, found := dp.get(&g.colliders, handle^)
	if !found {
		mrb.raise_exception(state, "Failed to access collider: %d", handle)
	}

	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)collider.size.x),
		mrb.float_value(state, cast(mrb.Float)collider.size.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
collider_other_collisions :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	handle := mrb.get_data_from_value(ColliderHandle, self)^
	if !(handle in g.collision_evts_t) {
		mrb.ary_new(state)
	}
	collided_with := g.collision_evts_t[handle]
	out := make([]mrb.Value, len(collided_with), context.temp_allocator)
	for e, idx in collided_with {
		mrb_v := mrb.int_value(state, cast(mrb.Int)e)
		mrb_e := mrb.obj_new(state, engine_classes.collider, 1, &mrb_v)
		out[idx] = mrb_e
	}
	values := mrb.ary_new_from_values(state, len(out), raw_data(out))

	return mrb.obj_new(state, engine_classes.set, 1, &values)
}


@(private = "file")
collider_create :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	KValues :: struct {
		pos:  mrb.Value,
		size: mrb.Value,
	}
	values: KValues
	load_kwargs(KValues, state, &values)

	assert(!mrb.undef_p(values.pos), "Entity Required for `pos:`")
	assert(!mrb.undef_p(values.size), "Entity Required for `size:`")
	pos := vector_from_object(state, values.pos)
	size := vector_from_object(state, values.size)

	collider_ptr, handle, success := dp.add_empty(&g.colliders)
	assert(success, "Failed to Create Entity")

	collider_ptr.pos = pos
	collider_ptr.size = size

	id := mrb.int_value(state, cast(mrb.Int)handle)
	return mrb.obj_new(state, engine_classes.collider, 1, &id)
}

//////////////////////////////
//// Vector
//////////////////////////////

setup_vector_class :: proc(st: ^mrb.State) {
	vector_class := mrb.define_class(st, "Vector", mrb.state_get_object_class(st))
	mrb.set_data_type(vector_class, .CData)
	mrb.define_class_method(st, vector_class, "zero", vector_zero, mrb.args_none())
	mrb.define_method(st, vector_class, "initialize", vector_init, mrb.args_req(2))
	mrb.define_method(st, vector_class, "x", vector_get_x, mrb.args_none())
	mrb.define_method(st, vector_class, "x=", vector_set_x, mrb.args_req(1))
	mrb.define_method(st, vector_class, "y", vector_get_y, mrb.args_none())
	mrb.define_method(st, vector_class, "y=", vector_set_y, mrb.args_req(1))
	mrb.define_method(st, vector_class, "*", vector_scale, mrb.args_req(1))
	mrb.define_method(st, vector_class, "+", vector_add, mrb.args_req(1))
	mrb.define_method(st, vector_class, "-", vector_minus, mrb.args_req(1))
	mrb.define_method(st, vector_class, "==", vector_eq, mrb.args_req(1))
	mrb.define_method(st, vector_class, "lerp", vector_lerp, mrb.args_req(2))
	mrb.define_method(st, vector_class, "angle", vector_angle, mrb.args_none())
	mrb.define_method(st, vector_class, "angle_between", vector_angle_between, mrb.args_req(1))
	mrb.define_method(st, vector_class, "length", vector_length, mrb.args_none())
	mrb.define_method(st, vector_class, "normalize", vector_normalize, mrb.args_none())
	mrb.define_method(st, vector_class, "floor!", vector_floor, mrb.args_none())
	mrb.define_method(st, vector_class, "round!", vector_round, mrb.args_none())
	mrb.define_method(st, vector_class, "dup", vector_dup, mrb.args_none())
	engine_classes.vector = vector_class
}


vector_from_object :: proc(state: ^mrb.State, v: mrb.Value, loc := #caller_location) -> Vector2 {
	assert(
		mrb.obj_is_kind_of(state, v, engine_classes.vector),
		fmt.tprintf("Expected Object to be a Vector @ %v", loc),
	)
	return mrb.get_data_from_value(Vector2, v)^
}


vector_obj_from_vec :: proc "contextless" (
	state: ^mrb.State,
	vec: Vector2,
	loc := #caller_location,
) -> mrb.Value {
	x := mrb.float_value(state, cast(mrb.Float)vec.x)
	y := mrb.float_value(state, cast(mrb.Float)vec.y)
	values := []mrb.Value{x, y}
	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values[:]))
}

@(private = "file")
vector_zero :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	x := mrb.float_value(state, 0)
	y := mrb.float_value(state, 0)
	values := []mrb.Value{x, y}
	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values[:]))
}

@(private = "file")
vector_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	inc_x: mrb.Float
	inc_y: mrb.Float
	mrb.get_args(state, "ff", &inc_x, &inc_y)

	v := mrb.get_data_from_value(Vector2, self)
	if (v == nil) {
		mrb.data_init(self, nil, &mrb_vector_type)
		v = cast(^Vector2)mrb.malloc(state, size_of(Vector2))
		mrb.data_init(self, v, &mrb_vector_type)
	}
	v.x = cast(f32)inc_x
	v.y = cast(f32)inc_y
	return self
}

@(private = "file")
vector_get_x :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(Vector2, self)
	return mrb.float_value(state, cast(mrb.Float)v.x)
}

@(private = "file")
vector_set_x :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	new_x: mrb.Float
	mrb.get_args(state, "f", &new_x)

	v := mrb.get_data_from_value(Vector2, self)
	v.x = cast(f32)new_x
	return mrb.nil_value()
}


@(private = "file")
vector_get_y :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(Vector2, self)
	return mrb.float_value(state, cast(mrb.Float)v.y)
}

@(private = "file")
vector_set_y :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	new_y: mrb.Float
	mrb.get_args(state, "f", &new_y)

	v := mrb.get_data_from_value(Vector2, self)
	v.y = cast(f32)new_y
	return mrb.nil_value()
}

@(private = "file")
vector_scale :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	scale: mrb.Float
	mrb.get_args(state, "f", &scale)

	v := mrb.get_data_from_value(Vector2, self)
	new_v := [2]mrb.Value {
		mrb.float_value(state, cast(mrb.Float)v.x * scale),
		mrb.float_value(state, cast(mrb.Float)v.y * scale),
	}


	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(new_v[:]))
}

@(private = "file")
vector_lerp :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	other: mrb.Value
	t: mrb.Float
	mrb.get_args(state, "of", &other, &t)
	assert(
		mrb.obj_is_kind_of(state, other, engine_classes.vector),
		"can only add two Vectors together",
	)
	a := mrb.get_data_from_value(Vector2, self)^
	b := mrb.get_data_from_value(Vector2, other)^

	c := math.lerp(a, b, cast(f32)t)
	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)c.x),
		mrb.float_value(state, cast(mrb.Float)c.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
vector_eq :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	other_v: mrb.Value
	mrb.get_args(state, "o", &other_v)
	assert(
		mrb.obj_is_kind_of(state, other_v, engine_classes.vector),
		"Vector can only equal another Vector",
	)

	a := mrb.get_data_from_value(Vector2, self)^
	b := mrb.get_data_from_value(Vector2, other_v)^


	return mrb.bool_value(a == b)
}


@(private = "file")
vector_add :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	other: mrb.Value
	mrb.get_args(state, "o", &other)
	assert(
		mrb.obj_is_kind_of(state, other, engine_classes.vector),
		"can only add two Vectors together",
	)
	a := mrb.get_data_from_value(rl.Vector2, self)
	b := mrb.get_data_from_value(Vector2, other)

	c := a^ + b^

	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)c.x),
		mrb.float_value(state, cast(mrb.Float)c.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
vector_minus :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	other: mrb.Value
	mrb.get_args(state, "o", &other)
	assert(
		mrb.obj_is_kind_of(state, other, engine_classes.vector),
		"can only add two Vectors together",
	)
	a := mrb.get_data_from_value(rl.Vector2, self)
	b := mrb.get_data_from_value(Vector2, other)

	c := a^ - b^
	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)c.x),
		mrb.float_value(state, cast(mrb.Float)c.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}


@(private = "file")
vector_normalize :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	old := mrb.get_data_from_value(rl.Vector2, self)^
	new := math.normalize(old)


	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)new.x),
		mrb.float_value(state, cast(mrb.Float)new.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
vector_floor :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	old := mrb.get_data_from_value(rl.Vector2, self)
	new := math.floor(old^)

	old^ = new

	return self
}

@(private = "file")
vector_round :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	old := mrb.get_data_from_value(rl.Vector2, self)
	new := math.round(old^)

	old^ = new

	return self
}


@(private = "file")
vector_angle :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	old := mrb.get_data_from_value(rl.Vector2, self)

	angle := math.atan2(old.y, old.x)

	return mrb.float_value(state, cast(mrb.Float)angle)
}

@(private = "file")
vector_angle_between :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	other: mrb.Value
	mrb.get_args(state, "o", &other)

	a := mrb.get_data_from_value(rl.Vector2, self)^
	b := mrb.get_data_from_value(rl.Vector2, other)^

	c := b - a

	c = math.normalize(c)
	angle := math.atan2(c.y, c.x)

	return mrb.float_value(state, cast(mrb.Float)angle)
}

@(private = "file")
vector_length :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	v := mrb.get_data_from_value(rl.Vector2, self)^

	return mrb.float_value(state, cast(mrb.Float)math.length(v))
}

@(private = "file")
vector_dup :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	old := vector_from_object(state, self)
	return vector_obj_from_vec(state, old)
}

//////////////////////////////
//// Color
//////////////////////////////

setup_color_class :: proc(st: ^mrb.State) {
	color_class := mrb.define_class(st, "Color", mrb.state_get_object_class(st))
	mrb.set_data_type(color_class, .CData)
	mrb.define_method(st, color_class, "initialize", color_init, mrb.args_req(4))
	mrb.define_method(st, color_class, "red", color_get_r, mrb.args_none())
	mrb.define_method(st, color_class, "red=", color_set_r, mrb.args_req(1))
	mrb.define_method(st, color_class, "blue", color_get_b, mrb.args_none())
	mrb.define_method(st, color_class, "blue=", color_set_b, mrb.args_req(1))
	mrb.define_method(st, color_class, "green", color_get_g, mrb.args_none())
	mrb.define_method(st, color_class, "green=", color_set_g, mrb.args_req(1))
	mrb.define_method(st, color_class, "alpha", color_get_a, mrb.args_none())
	mrb.define_method(st, color_class, "alpha=", color_set_a, mrb.args_req(1))

	mrb.define_alias(st, color_class, "r", "red")
	mrb.define_alias(st, color_class, "b", "blue")
	mrb.define_alias(st, color_class, "g", "green")
	mrb.define_alias(st, color_class, "a", "alpha")
	mrb.define_alias(st, color_class, "r=", "red=")
	mrb.define_alias(st, color_class, "b=", "blue=")
	mrb.define_alias(st, color_class, "g=", "green=")
	mrb.define_alias(st, color_class, "a=", "alpha=")


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
	engine_classes.color = color_class
}

color_object_new :: proc "contextless" (state: ^mrb.State, color: rl.Color) -> mrb.Value {
	colors: [4]mrb.Value
	for val, idx in color {colors[idx] = mrb.int_value(state, cast(mrb.Int)val)}

	return mrb.obj_new(state, engine_classes.color, len(colors), raw_data(colors[:]))
}

color_from_object :: proc(state: ^mrb.State, v: mrb.Value, loc := #caller_location) -> rl.Color {
	assert(
		mrb.obj_is_kind_of(state, v, engine_classes.color),
		fmt.tprintf("Expected Object to be a Color @ %v", loc),
	)
	return mrb.get_data_from_value(rl.Color, v)^
}

@(private = "file")
color_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	r, b, g, a: int
	mrb.get_args(state, "iiii", &r, &g, &b, &a)

	v: ^Color = mrb.get_data_from_value(Color, self)
	if (v == nil) {
		mrb.data_init(self, nil, &mrb_color_type)
		v = cast(^Color)mrb.malloc(state, size_of(Color))
		mrb.data_init(self, v, &mrb_color_type)
	}
	v.r = cast(u8)math.clamp(r, 0, 255)
	v.b = cast(u8)math.clamp(b, 0, 255)
	v.g = cast(u8)math.clamp(g, 0, 255)
	v.a = cast(u8)math.clamp(a, 0, 255)
	return self
}

@(private = "file")
color_get_r :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(Color, self)
	return mrb.int_value(state, cast(mrb.Int)v.r)
}

@(private = "file")
color_get_b :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(Color, self)
	return mrb.int_value(state, cast(mrb.Int)v.b)
}

@(private = "file")
color_get_g :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(Color, self)
	return mrb.int_value(state, cast(mrb.Int)v.g)
}

@(private = "file")
color_get_a :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	v := mrb.get_data_from_value(rl.Color, self)
	return mrb.int_value(state, cast(mrb.Int)v.a)
}

@(private = "file")
color_set_r :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	value: mrb.Int
	mrb.get_args(state, "i", &value)
	new_value := cast(u8)math.clamp(value, 0, 255)

	v := mrb.get_data_from_value(Color, self)
	v.r = new_value

	return mrb.nil_value()
}

@(private = "file")
color_set_b :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	value: mrb.Int
	mrb.get_args(state, "i", &value)
	new_value := cast(u8)math.clamp(value, 0, 255)

	v := mrb.get_data_from_value(Color, self)
	v.b = new_value

	return mrb.nil_value()
}

@(private = "file")
color_set_g :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	value: mrb.Int
	mrb.get_args(state, "i", &value)
	new_value := cast(u8)math.clamp(value, 0, 255)

	v := mrb.get_data_from_value(Color, self)
	v.g = new_value

	return mrb.nil_value()
}

@(private = "file")
color_set_a :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	value: mrb.Int
	mrb.get_args(state, "i", &value)
	new_value := cast(u8)math.clamp(value, 0, 255)

	v := mrb.get_data_from_value(Color, self)
	v.a = new_value

	return mrb.nil_value()
}


@(private = "file")
color_from_pallet :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	method_name := mrb.get_mid(state)
	str := mrb.sym_to_string(state, method_name)

	pallet, success := color_pallet_from_snake(str)
	assert(success, fmt.tprintf("Pallet method is not correct: %s", str))

	color := pallet_to_color[pallet]
	colors: [4]mrb.Value

	for val, idx in color {colors[idx] = mrb.int_value(state, cast(mrb.Int)val)}

	return mrb.obj_new(state, engine_classes.color, len(colors), raw_data(colors[:]))
}

//////////////////////////////
//// Draw
//////////////////////////////

setup_draw :: proc(st: ^mrb.State) {
	draw_module := mrb.define_module(st, "Draw")
	engine_classes.draw_module = draw_module
	mrb.define_class_method(st, draw_module, "text", draw_draw_text, mrb.args_key(5, 0))
	mrb.define_class_method(st, draw_module, "rect", draw_draw_rect, mrb.args_key(5, 0))
	mrb.define_class_method(st, draw_module, "line", draw_draw_line, mrb.args_key(4, 0))
	mrb.define_class_method(st, draw_module, "texture", draw_draw_texture, mrb.args_key(4, 0))
	mrb.define_class_method(st, draw_module, "measure_text", draw_measure_text, mrb.args_key(4, 0))
	mrb.define_class_method(st, draw_module, "scissor_begin", draw_scissor_begin, mrb.args_req(4))
	mrb.define_class_method(st, draw_module, "scissor_end", draw_scissor_end, mrb.args_none())

}

@(private = "file")
draw_draw_text :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	NumOfArgs :: 6
	kwargs: mrb.Kwargs
	kwargs.num = NumOfArgs

	KValues :: struct {
		text:   mrb.Value,
		pos:    mrb.Value,
		size:   mrb.Value,
		color:  mrb.Value,
		font:   mrb.Value,
		halign: mrb.Value,
	}

	// TODO: I can totally do this with generics and reflection
	names: []mrb.Sym =  {
		mrb.sym_from_string(state, "text"),
		mrb.sym_from_string(state, "pos"),
		mrb.sym_from_string(state, "size"),
		mrb.sym_from_string(state, "color"),
		mrb.sym_from_string(state, "font"),
		mrb.sym_from_string(state, "halign"),
	}
	values: KValues
	kwargs.table = raw_data(names[:])
	kwargs.values = transmute([^]mrb.Value)&values

	mrb.get_args(state, ":", &kwargs)
	assert(!mrb.undef_p(values.text), "Entity Required for `text:`")
	assert(!mrb.undef_p(values.pos), "Entity Required for `pos:`")
	cmd: ImuiDrawTextCmd

	txt := string(mrb.str_to_cstr(state, values.text))

	cmd.txt = strings.clone_to_cstring(txt, context.temp_allocator)
	cmd.pos = mrb.get_data_from_value(Vector2, values.pos)^

	cmd.size = 24
	if !mrb.undef_p(values.size) {
		cmd.size = cast(f32)mrb.as_float(state, values.size)
	}

	// Spacing
	cmd.spacing = 2
	cmd.color = extract_color_from_value(state, values.color, rl.WHITE)
	if !mrb.undef_p(values.font) && !mrb.nil_p(values.font) {
		assert(
			mrb.obj_is_kind_of(state, values.font, engine_classes.font_asset),
			"`:font` must be a Font",
		)

		cmd.font = mrb.get_data_from_value(FontHandle, values.font)^
	}
	if !mrb.undef_p(values.halign) && !mrb.nil_p(values.halign) {
		assert(mrb.symbol_p(values.halign), "halign: should be `:left`, `:right`, or `:center`")
		halign := mrb.obj_to_sym(state, values.halign)
		str := mrb.sym_to_string(state, halign)
		str_c := strings.to_pascal_case(str, context.temp_allocator)
		alignment, success := reflect.enum_from_name(HorizontalAlignment, str_c)
		assert(success, "halign: should be `:left`, `:right`, or `:center`")
		cmd.halign = alignment
	}

	imui_add_cmd(&g.imui, cmd)

	return mrb.nil_value()
}

@(private = "file")
draw_draw_rect :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	NumOfArgs :: 5
	kwargs: mrb.Kwargs
	kwargs.num = NumOfArgs

	KValues :: struct {
		pos:      mrb.Value,
		size:     mrb.Value,
		offset_p: mrb.Value,
		color:    mrb.Value,
		mode:     mrb.Value,
	}

	// TODO: I can totally do this with generics and reflection

	names: [NumOfArgs]string = {"pos", "size", "anchor_percentage", "color", "mode"}
	syms: [NumOfArgs]mrb.Sym = {}

	for n, idx in names {syms[idx] = mrb.sym_from_string(state, n)}

	values: KValues

	kwargs.table = raw_data(syms[:])
	kwargs.values = transmute([^]mrb.Value)&values

	mrb.get_args(state, ":", &kwargs)

	assert(!mrb.undef_p(values.pos), "`:pos` is required")
	assert(!mrb.undef_p(values.size), "`:size` is required")

	cmd: ImuiDrawRectCmd
	cmd.pos = mrb.get_data_from_value(Vector2, values.pos)^
	cmd.size = mrb.get_data_from_value(Vector2, values.size)^

	if !mrb.undef_p(values.offset_p) {
		cmd.offset_p = math.clamp(
			mrb.get_data_from_value(Vector2, values.offset_p)^,
			Vector2{},
			Vector2{1, 1},
		)
	} else {
		cmd.offset_p = {0.5, 0.5}
	}

	cmd.color = extract_color_from_value(state, values.color, rl.RED)

	if !mrb.undef_p(values.mode) {
		mode_sym := mrb.symbol_p(values.mode)
		assert(mode_sym, "Expect the alignment as symbol of `:solid` or `:outline`")

		sym := mrb.obj_to_sym(state, values.mode)
		sym_name := mrb.sym_to_string(state, sym)
		v := strings.to_pascal_case(sym_name, context.temp_allocator)

		mode, success := reflect.enum_from_name(DrawMode, v)
		assert(success, "Expect the alignment as symbol of `:solid` or `:outline`")

		cmd.mode = mode
	}

	imui_add_cmd(&g.imui, cmd)

	return mrb.nil_value()
}

@(private = "file")
draw_draw_line :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	NumOfArgs :: 4
	kwargs: mrb.Kwargs
	kwargs.num = NumOfArgs

	KValues :: struct {
		start, end: mrb.Value,
		thickness:  mrb.Value,
		color:      mrb.Value,
	}

	names: [NumOfArgs]string = {"start", "end", "thickness", "color"}
	syms: [NumOfArgs]mrb.Sym = {}

	for n, idx in names {syms[idx] = mrb.sym_from_string(state, n)}

	values: KValues

	kwargs.table = raw_data(syms[:])
	kwargs.values = transmute([^]mrb.Value)&values

	mrb.get_args(state, ":", &kwargs)

	assert(!mrb.undef_p(values.start), "`:start` is required")
	assert(!mrb.undef_p(values.end), "`:end` is required")

	cmd: ImuiDrawLineCmd
	cmd.start = mrb.get_data_from_value(Vector2, values.start)^
	cmd.end = mrb.get_data_from_value(Vector2, values.end)^
	cmd.thickness = 2

	if !mrb.undef_p(values.thickness) {
		cmd.thickness = math.max(cast(f32)mrb.as_float(state, values.thickness), 0)
	}

	cmd.color = extract_color_from_value(state, values.color, rl.RED)

	imui_add_cmd(&g.imui, cmd)

	return mrb.nil_value()
}

@(private = "file")
draw_draw_texture :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	KValues :: struct {
		pos:               mrb.Value,
		size:              mrb.Value,
		texture:           mrb.Value,
		offset_percentage: mrb.Value,
		rotation:          mrb.Value,
		tint:              mrb.Value,
	}

	values: KValues
	load_kwargs(KValues, state, &values)

	assert(!mrb.undef_p(values.pos), "Draw.texture requires `pos:`")
	assert(!mrb.undef_p(values.texture), "Draw.texture requires `pos:`")
	assert(
		mrb.obj_is_kind_of(state, values.texture, engine_classes.texture_asset),
		"expected `Draw.texture(texture:)` to be a Texture",
	)
	cmd: ImUiDrawTextureCmd
	cmd.pos = vector_from_object(state, values.pos)
	cmd.texture = texture_from_object(state, values.texture)
	cmd.offset_p = Vector2{0.5, 0.5}
	cmd.tint = rl.WHITE

	if mrb.undef_p(values.size) {
		txt_asset, txt_found := as_get_texture(&g.assets, cmd.texture)
		assert(txt_found, "Texture is not valid")
		cmd.size.x = txt_asset.src.width
		cmd.size.y = txt_asset.src.height
	} else {
		cmd.size = vector_from_object(state, values.size)
	}
	if !mrb.undef_p(values.tint) {cmd.tint = color_from_object(state, values.tint)}
	if !mrb.undef_p(values.rotation) {cmd.rotation = cast(f32)mrb.as_float(state, values.rotation)}
	if !mrb.undef_p(values.offset_percentage) {
		cmd.offset_p = vector_from_object(state, values.offset_percentage)
	}

	imui_add_cmd(&g.imui, cmd)

	return mrb.nil_value()
}


// TODO: Font should not be required
@(private = "file")
draw_measure_text :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	NumOfArgs :: 3
	kwargs: mrb.Kwargs
	kwargs.num = NumOfArgs

	KValues :: struct {
		text: mrb.Value,
		size: mrb.Value,
		font: mrb.Value,
	}

	names: []mrb.Sym =  {
		mrb.sym_from_string(state, "text"),
		mrb.sym_from_string(state, "size"),
		mrb.sym_from_string(state, "font"),
	}
	values: KValues
	kwargs.table = raw_data(names[:])
	kwargs.values = transmute([^]mrb.Value)&values

	mrb.get_args(state, ":", &kwargs)
	assert(mrb.string_p(values.text), "`:text` should be a String")
	assert(mrb.float_p(values.size) || mrb.integer_p(values.size), "`:size` should be a Float")
	assert(
		mrb.obj_is_kind_of(state, values.font, engine_classes.font_asset),
		"`:font` should be a Font",
	)
	text := mrb.string_cstr(state, values.text)
	size := cast(f32)mrb.as_float(state, values.size)
	// TODO: Handle nil
	font_handle := mrb.get_data_from_value(FontHandle, values.font)^

	font := as_get_font(&g.assets, font_handle)

	measurement := rl.MeasureTextEx(font.font, text, size, 2)

	out_values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)measurement.x),
		mrb.float_value(state, cast(mrb.Float)measurement.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(out_values))
}

@(private = "file")
draw_scissor_begin :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	left, top, width, height: mrb.Int
	mrb.get_args(state, "iiii", &left, &top, &width, &height)

	out := ImuiScissorBegin{cast(i32)left, cast(i32)top, cast(i32)width, cast(i32)height}

	imui_add_cmd(&g.imui, out)

	return mrb.nil_value()
}

@(private = "file")
draw_scissor_end :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	imui_add_cmd(&g.imui, ImuiScissorEnd{})
	return mrb.nil_value()
}

@(private = "file")
extract_color_from_value :: proc(
	state: ^mrb.State,
	value: mrb.Value,
	default: rl.Color,
) -> rl.Color {
	if !mrb.undef_p(value) {
		assert(
			mrb.obj_is_kind_of(state, value, engine_classes.color),
			"Draw.text(color: ) should be a Color",
		)
		return mrb.get_data_from_value(rl.Color, value)^
	}
	return default
}

//////////////////////////////
//// Assets
//////////////////////////////

setup_assets :: proc(st: ^mrb.State) {
	setup_fonts(st)
	setup_textures(st)
	setup_sounds(st)

	as_class := mrb.define_class(st, "AssetSystem", mrb.state_get_object_class(st))
	mrb.define_class_method(st, as_class, "add_font", assets_add_font, mrb.args_req(1))
	mrb.define_class_method(st, as_class, "load_texture", assets_load_texture, mrb.args_req(1))
	mrb.define_class_method(st, as_class, "load_sound", assets_load_sound, mrb.args_req(1))
	engine_classes.as = as_class
}

@(private = "file")
assets_load_texture :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	asset_system := &g.assets

	path: mrb.Value
	mrb.get_args(state, "o", &path)

	if !mrb.string_p(path) {
		mrb.raise_exception(state, "Expected the Texture pth to be a string")
		return mrb.nil_value()
	}
	path_str, success := mrb.string_from_value(state, path, context.temp_allocator)
	assert(success, "We should be able to always create a new string value")

	handle, texture_loaded := as_load_texture(&g.assets, path_str)
	if !texture_loaded {
		mrb.raise_exception(state, "Failed to Load Texture: %s", path_str)
		return mrb.nil_value()
	}

	handle_value := mrb.int_value(state, cast(mrb.Int)handle)

	return mrb.obj_new(state, engine_classes.texture_asset, 1, &handle_value)
}

@(private = "file")
assets_load_sound :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	asset_system := &g.assets

	path: mrb.Value
	mrb.get_args(state, "o", &path)

	if !mrb.string_p(path) {
		mrb.raise_exception(state, "Expected the Sound path to be a string")
		return mrb.nil_value()
	}
	path_str, success := mrb.string_from_value(state, path, context.temp_allocator)
	assert(success, "We should be able to always create a new string value")

	handle, sound_loaded := as_load_sound(&g.assets, path_str)
	if !sound_loaded {
		mrb.raise_exception(state, "Failed to Load Texture: %s", path_str)
		return mrb.nil_value()
	}

	handle_value := mrb.int_value(state, cast(mrb.Int)handle)

	return mrb.obj_new(state, engine_classes.sound, 1, &handle_value)
}

@(private = "file")
assets_add_font :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	name_data: [^]u8
	name_len: int
	mrb.get_args(state, "s", &name_data, &name_len)
	name := strings.string_from_ptr(name_data, name_len)

	// TOOD: Replace with proper raised exception
	handle, success := as_load_font(&g.assets, name)
	assert(success, fmt.tprintf("Failed to load %s for some reason", name))

	handle_v := mrb.int_value(state, cast(mrb.Int)handle)

	return mrb.obj_new(state, engine_classes.font_asset, 1, &handle_v)
}


//////////////////////////////
//// Sound
//////////////////////////////

setup_sounds :: proc(st: ^mrb.State) {
	sound_class := mrb.define_class(st, "Sound", mrb.state_get_object_class(st))
	mrb.set_data_type(sound_class, .CData)
	mrb.define_method(st, sound_class, "initialize", sound_init, mrb.args_req(1))
	mrb.define_method(st, sound_class, "id", sound_get_id, mrb.args_none())
	mrb.define_method(st, sound_class, "play", sound_play, mrb.args_key(2, 0))
	engine_classes.sound = sound_class
}

sound_from_object :: proc(
	state: ^mrb.State,
	v: mrb.Value,
	loc := #caller_location,
) -> SoundHandle {
	assert(
		mrb.obj_is_kind_of(state, v, engine_classes.sound),
		fmt.tprintf("Expected Object to be a Sound @ %v", loc),
	)
	return mrb.get_data_from_value(SoundHandle, v)^
}

@(private = "file")
sound_get_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	id := mrb.get_data_from_value(SoundHandle, self)^
	return mrb.int_value(state, cast(mrb.Int)id)
}

@(private = "file")
sound_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	handle_id: int
	mrb.get_args(state, "i", &handle_id)

	i := mrb.get_data_from_value(SoundHandle, self)

	if (i == nil) {
		mrb.data_init(self, nil, &mrb_font_handle_type)
		i = cast(^SoundHandle)mrb.malloc(state, size_of(SoundHandle))
		mrb.data_init(self, i, &mrb_font_handle_type)
	}
	i^ = cast(SoundHandle)handle_id
	return self
}

@(private = "file")
sound_play :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	KValues :: struct {
		volume: mrb.Value,
		pitch:  mrb.Value,
	}

	values: KValues
	load_kwargs(KValues, state, &values)

	snd_hndle := mrb.get_data_from_value(SoundHandle, self)^

	volume: f32 = 0.5
	if !mrb.undef_p(values.volume) {
		volume = cast(f32)mrb.as_float(state, values.volume)
		volume = math.clamp(volume, 0, 1)
	}
	pitch: f32 = 1
	if !mrb.undef_p(values.pitch) {
		pitch = cast(f32)mrb.as_float(state, values.pitch)
	}

	alias_hndle, alias := game_alias_sound(g, snd_hndle)
	rl.SetSoundVolume(alias, volume)
	rl.SetSoundPitch(alias, pitch)
	rl.PlaySound(alias)

	return mrb.nil_value()
}

//////////////////////////////
//// Textures
//////////////////////////////

setup_textures :: proc(st: ^mrb.State) {
	texture_asset_class := mrb.define_class(st, "Texture", mrb.state_get_object_class(st))
	mrb.set_data_type(texture_asset_class, .CData)
	mrb.define_method(st, texture_asset_class, "initialize", texture_init, mrb.args_req(1))
	mrb.define_method(st, texture_asset_class, "id", texture_get_id, mrb.args_none())
	mrb.define_method(st, texture_asset_class, "size", texture_get_size, mrb.args_none())
	engine_classes.texture_asset = texture_asset_class
}

texture_from_object :: proc(
	state: ^mrb.State,
	v: mrb.Value,
	loc := #caller_location,
) -> TextureHandle {
	assert(
		mrb.obj_is_kind_of(state, v, engine_classes.texture_asset),
		fmt.tprintf("Expected Object to be a Texture @ %v", loc),
	)
	return mrb.get_data_from_value(TextureHandle, v)^
}

@(private = "file")
texture_get_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	id := mrb.get_data_from_value(TextureHandle, self)^
	return mrb.int_value(state, cast(mrb.Int)id)
}


@(private = "file")
texture_get_size :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	id := mrb.get_data_from_value(TextureHandle, self)^
	asset, ok := as_get_texture(&g.assets, id)
	assert(ok, "Texture does not exist")
	src: rl.Rectangle = asset.src
	size := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)src.width),
		mrb.float_value(state, cast(mrb.Float)src.height),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(size))
}

@(private = "file")
texture_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	handle_id: int
	mrb.get_args(state, "i", &handle_id)

	i := mrb.get_data_from_value(TextureHandle, self)

	if (i == nil) {
		mrb.data_init(self, nil, &mrb_font_handle_type)
		i = cast(^TextureHandle)mrb.malloc(state, size_of(TextureHandle))
		mrb.data_init(self, i, &mrb_font_handle_type)
	}
	i^ = cast(TextureHandle)handle_id
	return self
}

//////////////////////////////
//// Fonts
//////////////////////////////

setup_fonts :: proc(st: ^mrb.State) {
	font_asset_class := mrb.define_class(st, "Font", mrb.state_get_object_class(st))
	mrb.set_data_type(font_asset_class, .CData)
	mrb.define_method(st, font_asset_class, "initialize", font_init, mrb.args_req(1))
	engine_classes.font_asset = font_asset_class
}

@(private = "file")
font_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	handle_id: int
	mrb.get_args(state, "i", &handle_id)

	i := mrb.get_data_from_value(FontHandle, self)

	if (i == nil) {
		mrb.data_init(self, nil, &mrb_font_handle_type)
		i = cast(^FontHandle)mrb.malloc(state, size_of(FontHandle))
		mrb.data_init(self, i, &mrb_font_handle_type)
	}
	i^ = cast(FontHandle)handle_id
	return self
}


//////////////////////////////
//// Engine
//////////////////////////////

setup_engine :: proc(st: ^mrb.State) {
	engine_module := mrb.define_module(st, "Engine")
	mrb.define_class_method(
		st,
		engine_module,
		"background_color=",
		engine_set_bg_color,
		mrb.args_req(1),
	)
	mrb.define_class_method(
		st,
		engine_module,
		"background_color",
		engine_get_bg_color,
		mrb.args_none(),
	)
	mrb.define_class_method(st, engine_module, "exit", engine_exit, mrb.args_none())
	mrb.define_class_method(st, engine_module, "debug?", engine_get_debug, mrb.args_none())
	mrb.define_class_method(st, engine_module, "debug=", engine_set_debug, mrb.args_req(1))
	mrb.define_class_method(st, engine_module, "hash_str", engine_hash_str, mrb.args_req(1))
	engine_classes.engine = engine_module
}

@(private = "file")
engine_get_debug :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return mrb.bool_value(g.debug)
}

@(private = "file")
engine_exit :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	g.should_exit = true
	return mrb.nil_value()
}

@(private = "file")
engine_set_debug :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	debug: bool
	mrb.get_args(state, "b", &debug)
	g.debug = debug
	return mrb.nil_value()
}

@(private = "file")
engine_hash_str :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	str: mrb.Value
	mrb.get_args(state, "o", &str)
	assert(mrb.string_p(str), "Engine.hash_str can only hash strings")
	cstr := mrb.string_cstr(state, str)
	hash := utils.generate_u64_from_cstring(cstr)
	return mrb.int_value(state, cast(mrb.Int)hash)
}


@(private = "file")
engine_set_bg_color :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	color_v: mrb.Value
	mrb.get_args(state, "o", &color_v)
	assert(
		mrb.obj_is_kind_of(state, color_v, engine_classes.color),
		"Expected argument should be a instance of `Color`",
	)

	color := mrb.get_data_from_value(rl.Color, color_v)
	g.bg_color = color^

	return mrb.nil_value()
}

@(private = "file")
engine_get_bg_color :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	color := g.bg_color
	colors := []mrb.Value {
		mrb.int_value(state, cast(mrb.Int)color.r),
		mrb.int_value(state, cast(mrb.Int)color.b),
		mrb.int_value(state, cast(mrb.Int)color.g),
		mrb.int_value(state, cast(mrb.Int)color.a),
	}

	return mrb.obj_new(state, engine_classes.color, 4, raw_data(colors))
}

//////////////////////////////
//// Sprite
//////////////////////////////

setup_sprite_class :: proc(state: ^mrb.State) {
	sprite_class := mrb.define_class(state, "Sprite", mrb.state_get_object_class(state))
	mrb.set_data_type(sprite_class, .CData)
	engine_classes.sprite = sprite_class

	mrb.define_method(state, sprite_class, "initialize", sprite_new, mrb.args_req(1))
	mrb.define_class_method(state, sprite_class, "create", sprite_create, mrb.args_key(2, 0))
	mrb.define_method(state, sprite_class, "id", sprite_get_id, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "pos=", sprite_pos_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "pos", sprite_pos_get, mrb.args_none())
	mrb.define_method(state, sprite_class, "size=", sprite_size_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "size", sprite_size_get, mrb.args_none())
	mrb.define_method(state, sprite_class, "z_offset=", sprite_z_offset_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "z_offset", sprite_z_offset_get, mrb.args_none())
	mrb.define_method(state, sprite_class, "parallax=", sprite_parallax_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "parallax", sprite_parallax_get, mrb.args_none())
	mrb.define_method(
		state,
		sprite_class,
		"parallax_pos",
		sprite_parallax_pos_get,
		mrb.args_none(),
	)

	mrb.define_method(state, sprite_class, "texture=", sprite_texture_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "texture", sprite_texture_get, mrb.args_none())

	mrb.define_method(state, sprite_class, "tint=", sprite_tint_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "tint", sprite_tint_get, mrb.args_none())
	mrb.define_method(state, sprite_class, "valid?", sprite_is_valid, mrb.args_none())

	mrb.define_method(state, sprite_class, "visible=", sprite_visible_set, mrb.args_req(1))
	mrb.define_method(state, sprite_class, "visible?", sprite_visible_get, mrb.args_none())
	mrb.define_method(state, sprite_class, "destroy", sprite_destroy, mrb.args_none())
}


@(private = "file")
sprite_from_object :: proc(state: ^mrb.State, v: mrb.Value) -> ^Sprite {
	hnd := mrb.get_data_from_value(SpriteHandle, v)^
	spr: ^Sprite = dp.get_ptr(&g.sprites, hnd)
	return spr
}


@(private = "file")
sprite_new :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	handle_id: int
	mrb.get_args(state, "i", &handle_id)

	sprite_handle := init_cdata(SpriteHandle, state, self, &mrb_sprite_type)
	sprite_handle^ = cast(SpriteHandle)handle_id
	return self
}

@(private = "file")
sprite_create :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	KValues :: struct {
		texture:  mrb.Value,
		pos:      mrb.Value,
		size:     mrb.Value,
		tint:     mrb.Value,
		z_offset: mrb.Value,
		parallax: mrb.Value,
	}

	values: KValues

	load_kwargs(KValues, state, &values)

	assert(!mrb.undef_p(values.texture), "Sprite Required for `texture:`")
	assert(!mrb.undef_p(values.size), "Vector Required for `size:`")
	assert(
		mrb.obj_is_kind_of(state, values.texture, engine_classes.texture_asset),
		"`texture:` should be a `Texture`",
	)
	assert(
		mrb.obj_is_kind_of(state, values.texture, engine_classes.texture_asset),
		"`size:` should be a `Size`",
	)

	spr, handle, success := dp.add_empty(&g.sprites)
	assert(success)

	spr.texture = mrb.get_data_from_value(TextureHandle, values.texture)^
	spr.size = mrb.get_data_from_value(Vector2, values.size)^
	spr.tint = rl.WHITE
	spr.visible = true

	if !mrb.undef_p(values.pos) {
		assert(
			mrb.obj_is_kind_of(state, values.pos, engine_classes.vector),
			"Expect `pos:` to be a Vector",
		)
		spr.pos = mrb.get_data_from_value(Vector2, values.pos)^
	}


	if !mrb.undef_p(values.tint) {
		assert(
			mrb.obj_is_kind_of(state, values.tint, engine_classes.color),
			"Expect `tint:` to be a Color",
		)
		spr.tint = mrb.get_data_from_value(rl.Color, values.tint)^
	}

	if !mrb.undef_p(values.z_offset) {
		spr.z_offset = cast(f32)mrb.as_float(state, values.z_offset)
	}


	if !mrb.undef_p(values.parallax) {
		spr.parallax = cast(f32)mrb.as_float(state, values.parallax)
	}

	v := mrb.int_value(state, cast(mrb.Int)handle)
	return mrb.obj_new(state, engine_classes.sprite, 1, &v)
}

@(private = "file")
sprite_get_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	return mrb.int_value(state, cast(mrb.Int)hnd)
}


@(private = "file")
sprite_pos_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	vec_v: mrb.Value
	mrb.get_args(state, "o", &vec_v)
	vec := vector_from_object(state, vec_v)
	hnd := mrb.get_data_from_value(SpriteHandle, self)^

	spr := dp.get_ptr(&g.sprites, hnd)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", hnd))
	spr.pos = vec

	return mrb.nil_value()
}

@(private = "file")
sprite_pos_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr, found := dp.get(&g.sprites, hnd)
	assert(found, fmt.tprintf("Sprite should exist: %s", hnd))

	positions := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)spr.pos.x),
		mrb.float_value(state, cast(mrb.Float)spr.pos.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(positions))
}


@(private = "file")
sprite_size_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	vec_v: mrb.Value
	mrb.get_args(state, "o", &vec_v)
	vec := vector_from_object(state, vec_v)
	hnd := mrb.get_data_from_value(SpriteHandle, self)^

	spr := dp.get_ptr(&g.sprites, hnd)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", hnd))
	spr.size = vec

	return mrb.nil_value()
}

@(private = "file")
sprite_size_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr, found := dp.get(&g.sprites, hnd)
	assert(found, fmt.tprintf("Sprite should exist: %s", hnd))

	return vector_obj_from_vec(state, spr.size)
}

@(private = "file")
sprite_z_offset_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	offset: mrb.Float
	mrb.get_args(state, "f", &offset)
	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr: ^Sprite = dp.get_ptr(&g.sprites, hnd)

	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", hnd))
	spr.z_offset = cast(f32)offset

	return mrb.nil_value()
}

@(private = "file")
sprite_z_offset_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	spr := sprite_from_object(state, self)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", spr))

	return mrb.float_value(state, cast(mrb.Float)spr.z_offset)
}

@(private = "file")
sprite_parallax_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	parallax: mrb.Float
	mrb.get_args(state, "f", &parallax)
	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr: ^Sprite = dp.get_ptr(&g.sprites, hnd)

	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", hnd))
	spr.parallax = cast(f32)parallax

	return mrb.nil_value()
}


@(private = "file")
sprite_parallax_pos_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	spr := sprite_from_object(state, self)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", spr))
	p_offset := game_parallax_offset(g, spr.parallax)
	parallax_pos := spr.pos + p_offset

	return vector_obj_from_vec(state, parallax_pos)
}

@(private = "file")
sprite_parallax_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	spr := sprite_from_object(state, self)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", spr))

	return mrb.float_value(state, cast(mrb.Float)spr.parallax)
}

@(private = "file")
sprite_is_valid :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	return mrb.bool_value(dp.valid(&g.sprites, hnd))
}

@(private = "file")
sprite_texture_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr, found := dp.get(&g.sprites, hnd)
	assert(found, fmt.tprintf("Sprite should exist: %s", hnd))

	values := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)spr.pos.x),
		mrb.float_value(state, cast(mrb.Float)spr.pos.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}


@(private = "file")
sprite_texture_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	texture_v: mrb.Value
	mrb.get_args(state, "o", &texture_v)

	texture := texture_from_object(state, texture_v)
	hnd := mrb.get_data_from_value(SpriteHandle, self)^

	spr := dp.get_ptr(&g.sprites, hnd)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", hnd))
	spr.texture = texture

	return mrb.nil_value()
}

@(private = "file")
sprite_tint_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	color_v: mrb.Value
	mrb.get_args(state, "o", &color_v)

	color := color_from_object(state, color_v)
	hnd := mrb.get_data_from_value(SpriteHandle, self)^

	spr := dp.get_ptr(&g.sprites, hnd)
	assert(spr != nil, fmt.tprintf("Sprite should exist: %s", hnd))
	spr.tint = color

	return mrb.nil_value()
}


@(private = "file")
sprite_tint_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr, found := dp.get(&g.sprites, hnd)
	assert(found, fmt.tprintf("Sprite should exist: %s", hnd))
	return color_object_new(state, spr.tint)
}

@(private = "file")
sprite_visible_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	visible: bool
	mrb.get_args(state, "b", &visible)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr: ^Sprite = dp.get_ptr(&g.sprites, hnd)
	spr.visible = visible

	return mrb.nil_value()
}

@(private = "file")
sprite_visible_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	spr, found := dp.get(&g.sprites, hnd)
	assert(found, fmt.tprintf("Sprite should exist: %s", hnd))
	return mrb.bool_value(spr.visible)
}

@(private = "file")
sprite_destroy :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	hnd := mrb.get_data_from_value(SpriteHandle, self)^
	assert(hnd != 0, "SpriteHandle should not be 0")

	if !dp.valid(&g.sprites, hnd) {
		mrb.bool_value(false)
	}
	success := dp.remove(&g.sprites, hnd)
	return mrb.bool_value(success)
}

//////////////////////////////
//// Camera
//////////////////////////////

// TODO: Implement Camera Valid?
setup_camera_class :: proc(state: ^mrb.State) {
	camera_class := mrb.define_class(state, "Camera", mrb.state_get_object_class(state))
	mrb.set_data_type(camera_class, .CData)
	engine_classes.camera = camera_class

	mrb.define_method(state, camera_class, "initialize", camera_new, mrb.args_req(1))
	mrb.define_class_method(state, camera_class, "create", camera_create, mrb.args_key(4, 0))
	mrb.define_method(state, camera_class, "pos=", camera_pos_set, mrb.args_req(1))
	mrb.define_method(state, camera_class, "pos", camera_pos_get, mrb.args_none())
	mrb.define_method(state, camera_class, "offset=", camera_offset_set, mrb.args_req(1))
	mrb.define_method(state, camera_class, "offset", camera_offset_get, mrb.args_none())
	mrb.define_method(state, camera_class, "destroy", camera_destroy, mrb.args_none())
	mrb.define_method(
		state,
		camera_class,
		"world_to_screen",
		camera_world_to_screen,
		mrb.args_req(1),
	)
	mrb.define_method(
		state,
		camera_class,
		"screen_to_world",
		camera_screen_to_world,
		mrb.args_req(1),
	)

	mrb.define_class_method(state, camera_class, "current", camera_current_get, mrb.args_none())
	mrb.define_class_method(state, camera_class, "current=", camera_current_set, mrb.args_req(1))
}

@(private = "file")
camera_new :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	handle_id: int
	mrb.get_args(state, "i", &handle_id)

	camera_handle := init_cdata(CameraHandle, state, self, &mrb_sprite_type)
	camera_handle^ = cast(CameraHandle)handle_id
	return self
}

@(private = "file")
camera_create :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	KValues :: struct {
		pos:      mrb.Value,
		offset:   mrb.Value,
		rotation: mrb.Value,
		zoom:     mrb.Value,
	}
	values: KValues
	load_kwargs(KValues, state, &values)

	camera, handle, success := dp.add_empty(&g.cameras)
	assert(success, "Could not create a Camera")
	camera.zoom = 1

	if (!mrb.undef_p(values.pos) && mrb.obj_is_kind_of(state, values.pos, engine_classes.vector)) {
		camera.target = vector_from_object(state, values.pos)
	}
	if (!mrb.undef_p(values.offset) &&
		   mrb.obj_is_kind_of(state, values.offset, engine_classes.vector)) {
		camera.offset = vector_from_object(state, values.offset)
	}
	if (!mrb.undef_p(values.offset) && mrb.float_p(values.zoom)) {
		camera.zoom = cast(f32)mrb.as_float(state, values.zoom)
	}
	rhandle := mrb.int_value(state, cast(mrb.Int)handle)
	return mrb.obj_new(state, engine_classes.camera, 1, &rhandle)
}

camera_from_mrb_value :: proc(
	state: ^mrb.State,
	v: mrb.Value,
	loc := #caller_location,
) -> ^rl.Camera2D {
	assert(
		mrb.obj_is_kind_of(state, v, engine_classes.camera),
		fmt.tprintf("Expected Object to be a Camera @ %v", loc),
	)
	handle := mrb.get_data_from_value(CameraHandle, v)^
	assert(handle != 0, "CameraHandle is null")
	camera := dp.get_ptr(&g.cameras, handle)

	return camera
}

@(private = "file")
camera_pos_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	camera := camera_from_mrb_value(state, self)

	pos := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)camera.target.x),
		mrb.float_value(state, cast(mrb.Float)camera.target.y),
	}
	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(pos))
}

@(private = "file")
camera_pos_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	vector_v: mrb.Value
	mrb.get_args(state, "o", &vector_v)

	target := vector_from_object(state, vector_v)
	camera := camera_from_mrb_value(state, self)
	camera.target = target

	return mrb.nil_value()
}


@(private = "file")
camera_offset_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	camera := camera_from_mrb_value(state, self)

	pos := []mrb.Value {
		mrb.float_value(state, cast(mrb.Float)camera.offset.x),
		mrb.float_value(state, cast(mrb.Float)camera.offset.y),
	}
	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(pos))
}

@(private = "file")
camera_offset_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	offset_v: mrb.Value
	mrb.get_args(state, "o", &offset_v)

	target := vector_from_object(state, offset_v)
	camera := camera_from_mrb_value(state, self)
	camera.offset = target

	return mrb.nil_value()
}

// TODO: Implement Camera Destroy
@(private = "file")
camera_destroy :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return mrb.nil_value()
}

@(private = "file")
camera_world_to_screen :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	world_space_v: mrb.Value
	mrb.get_args(state, "o", &world_space_v)
	world_space := vector_from_object(state, world_space_v)

	camera := camera_from_mrb_value(state, self)
	screen_space := rl.GetWorldToScreen2D(world_space, camera^)

	return vector_obj_from_vec(state, screen_space)
}

@(private = "file")
camera_screen_to_world :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	screen_space_v: mrb.Value
	mrb.get_args(state, "o", &screen_space_v)
	screen_space := vector_from_object(state, screen_space_v)

	camera := camera_from_mrb_value(state, self)
	world_space := rl.GetScreenToWorld2D(screen_space, camera^)

	return vector_obj_from_vec(state, world_space)
}


@(private = "file")
camera_current_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	camera_v: mrb.Value
	mrb.get_args(state, "o", &camera_v)

	camera := mrb.get_data_from_value(CameraHandle, camera_v)^
	g.camera = camera

	return mrb.nil_value()
}

@(private = "file")
camera_current_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	camera_index := g.camera
	mrb_index := mrb.int_value(state, cast(mrb.Int)camera_index)
	return mrb.obj_new(state, engine_classes.camera, 1, &mrb_index)
}


//////////////////////////////
//// Screen
//////////////////////////////

setup_screen_class :: proc(state: ^mrb.State) {
	screen_class := mrb.define_class(state, "Screen", mrb.state_get_object_class(state))
	engine_classes.screen = screen_class

	mrb.define_method(state, screen_class, "size", screen_size, mrb.args_none())
	mrb.define_method(state, screen_class, "pos", screen_pos, mrb.args_none())
	mrb.define_method(state, screen_class, "anchor_percentage", screen_anchor, mrb.args_none())
}


@(private = "file")
screen_size :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	width, height := input.frame_query_dimensions(g.input)
	return vector_obj_from_vec(state, Vector2{width, height})
}

@(private = "file")
screen_pos :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return vector_obj_from_vec(state, Vector2{})
}

@(private = "file")
screen_anchor :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return vector_obj_from_vec(state, Vector2{})
}


//////////////////////////////
//// Rect Pack
//////////////////////////////

rect_pack_free :: proc "c" (state: ^mrb.State, p: rawptr) {
	context = load_context(state)

	defer mrb.free(state, p)
	rect_pack := cast(^RubyRectPack)p
	delete(rect_pack.nodes)
}

mrb_rect_pack_type: mrb.DataType = {"RectPack", rect_pack_free}

RubyRectPack :: struct {
	ctx:   rp.PackContext,
	nodes: []rp.Node,
}

setup_rect_pack_class :: proc(state: ^mrb.State) {
	rect_pack := mrb.define_class(state, "RectPack", mrb.state_get_object_class(state))
	engine_classes.rect_pack = rect_pack
	mrb.set_data_type(rect_pack, .CData)

	mrb.define_method(state, rect_pack, "initialize", rect_pack_new, mrb.args_key(4, 0))
	mrb.define_method(state, rect_pack, "pack!", rect_pack_pack, mrb.args_req(1))
}


@(private = "file")
rect_pack_new :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	KValues :: struct {
		width:     mrb.Value,
		height:    mrb.Value,
		num_nodes: mrb.Value,
		heuristic: mrb.Value,
	}
	values: KValues
	load_kwargs(KValues, state, &values)

	num_nodes: i32 = 50
	width: i32 = 1024
	height: i32 = 1024
	// TODO: load Hueristic from KWargs
	heuristic := rp.PackHeuristic.Skyline_default

	if !mrb.undef_p(values.num_nodes) {
		num_nodes = cast(i32)mrb.as_int(state, values.num_nodes)
	}
	if !mrb.undef_p(values.num_nodes) {
		width = cast(i32)mrb.as_int(state, values.width)
	}
	if !mrb.undef_p(values.num_nodes) {
		height = cast(i32)mrb.as_int(state, values.height)
	}

	rect_pack := init_cdata(RubyRectPack, state, self, &mrb_rect_pack_type)
	rect_pack.nodes = make([]rp.Node, num_nodes)
	rp.init_target(&rect_pack.ctx, width, height, rect_pack.nodes)

	return self
}

@(private = "file")
rect_pack_pack :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	rectangles: mrb.Value
	mrb.get_args(state, "o", &rectangles)

	rect_pack := mrb.get_data_from_value(RubyRectPack, self)
	width, height := rect_pack.ctx.width, rect_pack.ctx.height
	rp.init_target(&rect_pack.ctx, width, height, rect_pack.nodes)

	count_sym := mrb.sym_from_string(g.ruby, "count")
	size_sym := mrb.sym_from_string(g.ruby, "size")
	set_pos_sym := mrb.sym_from_string(g.ruby, "pos=")
	count_v := mrb.funcall_argv(g.ruby, rectangles, count_sym, 0, nil)
	count := mrb.as_int(state, count_v)

	rects := make([]rp.Rect, count, context.temp_allocator)

	for i := 0; i < count; i += 1 {
		entry := mrb.ary_entry(rectangles, i)
		size_v := mrb.funcall_argv(g.ruby, entry, size_sym, 0, nil)
		size := vector_from_object(state, size_v)
		rects[i].w = cast(i32)size.x
		rects[i].h = cast(i32)size.y
	}
	rp.pack_rects(&rect_pack.ctx, rects)

	for i := 0; i < count; i += 1 {
		rect := rects[i]
		new_pos := Vector2{cast(f32)rect.x, cast(f32)rect.y}
		fmt.println("new pos", new_pos, rect.x, rect.y)
		entry := mrb.ary_entry(rectangles, i)

		pos_v := vector_obj_from_vec(state, new_pos)

		mrb.funcall_argv(g.ruby, entry, set_pos_sym, 1, &pos_v)
	}

	return rectangles
}
