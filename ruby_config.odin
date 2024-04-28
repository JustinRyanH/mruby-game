package main

import "core:fmt"
import math "core:math/linalg"
import "core:math/rand"
import "core:reflect"
import "core:runtime"
import "core:strings"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"

load_context :: proc "contextless" (state: ^mrb.State) -> runtime.Context {
	ctx := transmute(^runtime.Context)mrb.state_alloc_ud(state)
	return ctx^
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

mrb_frame_input_type: mrb.DataType = {"FrameInput", mrb.free}
mrb_entity_handle_type: mrb.DataType = {"Entity", mrb.free}
mrb_font_handle_type: mrb.DataType = {"Font", mrb.free}
mrb_vector_type: mrb.DataType = {"Vector", mrb.free}
mrb_color_type: mrb.DataType = {"Color", mrb.free}
mrb_collision_evt_handle_type: mrb.DataType = {"CollisionEvent", mrb.free}

EngineRClass :: struct {
	as:            ^mrb.RClass,
	color:         ^mrb.RClass,
	draw_module:   ^mrb.RClass,
	engine:        ^mrb.RClass,
	entity:        ^mrb.RClass,
	font_asset:    ^mrb.RClass,
	frame:         ^mrb.RClass,
	vector:        ^mrb.RClass,
	texture_asset: ^mrb.RClass,
}

engine_classes: EngineRClass

game_load_mruby_raylib :: proc(game: ^Game) {
	st := game.ruby

	setup_engine(st)
	setup_assets(st)
	setup_draw(st)
	setup_input(st)
	setup_log_class(st)
	setup_entity_class(st)
	setup_vector_class(st)
	setup_color_class(st)
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
	mrb.define_class_method(
		st,
		frame_class,
		"screen_size",
		frame_input_screen_size,
		mrb.args_none(),
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
frame_input_screen_size :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	width, height := input.frame_query_dimensions(g.input)
	mrb_width, mrb_height := cast(f64)width, cast(f64)height
	return mrb.assoc_new(
		state,
		mrb.float_value(state, mrb_width),
		mrb.float_value(state, mrb_height),
	)
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
	v := rand.float64_range(cast(f64)low, cast(f64)high, &g.rand)

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
//// Entity
//////////////////////////////

setup_entity_class :: proc(st: ^mrb.State) {
	entity_class := mrb.define_class(st, "Entity", mrb.state_get_object_class(st))
	mrb.set_data_type(entity_class, .CData)
	mrb.define_method(st, entity_class, "initialize", entity_init, mrb.args_req(1))
	// Removes the Entity, returns true if is was destroyed,
	// return false if failed (likely because it was already destroyed)
	mrb.define_method(st, entity_class, "destroy", entity_destroy, mrb.args_none())
	mrb.define_method(st, entity_class, "id", entity_get_id, mrb.args_none())
	mrb.define_method(st, entity_class, "valid?", entity_valid, mrb.args_none())
	mrb.define_method(st, entity_class, "pos", entity_pos_get, mrb.args_none())
	mrb.define_method(st, entity_class, "pos=", entity_pos_set, mrb.args_req(1))
	mrb.define_method(st, entity_class, "visible", entity_visible_get, mrb.args_none())
	mrb.define_method(st, entity_class, "visible=", entity_visible_set, mrb.args_req(1))
	mrb.define_method(st, entity_class, "texture", entity_texture_get, mrb.args_none())
	mrb.define_method(st, entity_class, "texture=", entity_texture_set, mrb.args_req(1))
	mrb.define_method(st, entity_class, "size", entity_size_get, mrb.args_none())
	mrb.define_method(st, entity_class, "collisions", entity_collisions_get, mrb.args_none())
	mrb.define_method(st, entity_class, "==", entity_eq, mrb.args_req(1))
	mrb.define_class_method(st, entity_class, "create", entity_create, mrb.args_key(1, 0))

	mrb.define_alias(st, entity_class, "eql?", "==")
	mrb.define_alias(st, entity_class, "hash", "id")
	engine_classes.entity = entity_class
}

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
entity_destroy :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	i := mrb.get_data_from_value(EntityHandle, self)^
	assert(i != 0, "Entity Id should not be 0")

	if !dp.valid(&g.entities, i) {
		mrb.bool_value(false)
	}
	success := dp.remove(&g.entities, i)
	return mrb.bool_value(success)
}

@(private = "file")
entity_get_id :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(EntityHandle, self)
	success := dp.valid(&g.entities, handle^)
	if success {
		return mrb.int_value(state, cast(mrb.Int)handle^)
	}
	return mrb.nil_value()
}

@(private = "file")
entity_valid :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(EntityHandle, self)
	success := dp.valid(&g.entities, handle^)
	return mrb.bool_value(success)
}

@(private = "file")
entity_pos_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(EntityHandle, self)

	entity, found := dp.get(&g.entities, handle^)
	if !found {
		mrb.raise_exception(state, "Failed to access Entity: %d", handle^)
	}

	values := []mrb.Value {
		mrb.float_value(state, cast(f64)entity.pos.x),
		mrb.float_value(state, cast(f64)entity.pos.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
entity_pos_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	new_pos: mrb.Value
	mrb.get_args(state, "o", &new_pos)
	assert(
		mrb.obj_is_kind_of(state, new_pos, engine_classes.vector),
		"Can only assign Vector to position",
	)

	pos := mrb.get_data_from_value(Vector2, new_pos)

	i := mrb.get_data_from_value(EntityHandle, self)
	entity := dp.get_ptr(&g.entities, i^)
	if entity == nil {
		mrb.raise_exception(state, "Failed to access Entity: %d", i^)
	}
	entity.pos = pos^

	return mrb.nil_value()
}

@(private = "file")
entity_visible_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(EntityHandle, self)

	entity, found := dp.get(&g.entities, handle^)
	if !found {
		mrb.raise_exception(state, "Failed to access Entity: %d", handle^)
	}

	return mrb.bool_value(entity.visible)
}

@(private = "file")
entity_visible_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	new_value: bool
	mrb.get_args(state, "b", &new_value)

	i := mrb.get_data_from_value(EntityHandle, self)
	entity := dp.get_ptr(&g.entities, i^)
	if entity == nil {
		mrb.raise_exception(state, "Failed to access Entity: %d", i^)
	}
	entity.visible = new_value

	return mrb.nil_value()
}

@(private = "file")
entity_texture_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	eh := mrb.get_data_from_value(EntityHandle, self)^
	entity, found := dp.get(&g.entities, eh)
	if !found {mrb.raise_exception(state, "Failed to access Entity: %d", eh)}

	th := entity.texture

	th_value := mrb.int_value(state, cast(mrb.Int)th)

	return mrb.obj_new(state, engine_classes.texture_asset, 1, &th_value)
}

@(private = "file")
entity_texture_set :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	return mrb.nil_value()
}

@(private = "file")
entity_size_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	handle := mrb.get_data_from_value(EntityHandle, self)

	entity, found := dp.get(&g.entities, handle^)
	if !found {
		mrb.raise_exception(state, "Failed to access Entity: %d", handle)
	}

	values := []mrb.Value {
		mrb.float_value(state, cast(f64)entity.size.x),
		mrb.float_value(state, cast(f64)entity.size.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
entity_collisions_get :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)
	entity := mrb.get_data_from_value(EntityHandle, self)^
	if !(entity in g.collision_evts_t) {
		mrb.ary_new(state)
	}
	collided_with := g.collision_evts_t[entity]
	out := make([]mrb.Value, len(collided_with), context.temp_allocator)
	for e, idx in collided_with {
		mrb_v := mrb.int_value(state, cast(mrb.Int)e)
		mrb_e := mrb.obj_new(state, engine_classes.entity, 1, &mrb_v)
		out[idx] = mrb_e
	}

	return mrb.ary_new_from_values(state, len(out), raw_data(out))
}


@(private = "file")
entity_eq :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	other_v: mrb.Value
	mrb.get_args(state, "o", &other_v)
	assert(
		mrb.obj_is_kind_of(state, other_v, engine_classes.entity),
		"Entity can only equal another entity",
	)

	entity := mrb.get_data_from_value(EntityHandle, self)^
	other := mrb.get_data_from_value(EntityHandle, other_v)^

	return mrb.bool_value(entity == other)
}

@(private = "file")
entity_create :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	NumOfArgs :: 4
	kwargs: mrb.Kwargs
	kwargs.num = NumOfArgs

	names: [NumOfArgs]mrb.Sym =  {
		mrb.sym_from_string(state, "pos"),
		mrb.sym_from_string(state, "size"),
		mrb.sym_from_string(state, "color"),
		mrb.sym_from_string(state, "texture"),
	}
	values := [NumOfArgs]mrb.Value{}
	kwargs.table = raw_data(names[:])
	kwargs.values = raw_data(values[:])

	mrb.get_args(state, ":", &kwargs)
	assert(!mrb.undef_p(values[0]), "Entity Required for `pos:`")
	assert(!mrb.undef_p(values[1]), "Entity Required for `size:`")
	pos: Vector2 = mrb.get_data_from_value(Vector2, values[0])^
	size: Vector2 = mrb.get_data_from_value(Vector2, values[1])^

	color: rl.Color
	if (mrb.undef_p(values[2])) {
		color = rl.WHITE
	} else {
		color = mrb.get_data_from_value(Color, values[2])^
	}

	th: TextureHandle
	texture_value := values[3]
	if !mrb.undef_p(texture_value) &&
	   mrb.obj_is_kind_of(state, texture_value, engine_classes.texture_asset) {
		th = mrb.get_data_from_value(TextureHandle, texture_value)^
	}

	entity_ptr, handle, success := dp.add_empty(&g.entities)
	assert(success, "Failed to Create Entity")

	entity_ptr.pos = pos
	entity_ptr.size = size
	entity_ptr.color = color
	if th != 0 {
		entity_ptr.texture = th
	}
	entity_ptr.visible = true

	id := mrb.int_value(state, cast(mrb.Int)handle)
	collection: []mrb.Value = {id}
	return mrb.obj_new(state, engine_classes.entity, 1, raw_data(collection[:]))
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
	mrb.define_method(st, vector_class, "length", vector_length, mrb.args_none())
	mrb.define_method(st, vector_class, "normalize", vector_normalize, mrb.args_none())
	engine_classes.vector = vector_class
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
		mrb.float_value(state, cast(f64)v.x * scale),
		mrb.float_value(state, cast(f64)v.y * scale),
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
		mrb.float_value(state, cast(f64)c.x),
		mrb.float_value(state, cast(f64)c.y),
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

	entity := mrb.get_data_from_value(Vector2, self)^
	other := mrb.get_data_from_value(Vector2, self)^

	return mrb.bool_value(entity == other)
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
		mrb.float_value(state, cast(f64)c.x),
		mrb.float_value(state, cast(f64)c.y),
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
		mrb.float_value(state, cast(f64)c.x),
		mrb.float_value(state, cast(f64)c.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}


@(private = "file")
vector_normalize :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	old := mrb.get_data_from_value(rl.Vector2, self)^
	new := math.normalize(old)


	values := []mrb.Value {
		mrb.float_value(state, cast(f64)new.x),
		mrb.float_value(state, cast(f64)new.y),
	}

	return mrb.obj_new(state, engine_classes.vector, 2, raw_data(values))
}

@(private = "file")
vector_angle :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	old := mrb.get_data_from_value(rl.Vector2, self)

	angle := math.atan2(old.y, old.x)

	return mrb.float_value(state, cast(mrb.Float)angle)
}

@(private = "file")
vector_length :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	v := mrb.get_data_from_value(rl.Vector2, self)^

	return mrb.float_value(state, cast(mrb.Float)math.length(v))
}

//////////////////////////////
//// Color
//////////////////////////////

setup_color_class :: proc(st: ^mrb.State) {
	color_class := mrb.define_class(st, "Color", mrb.state_get_object_class(st))
	mrb.set_data_type(color_class, .CData)
	mrb.define_method(st, color_class, "initialize", color_init, mrb.args_req(4))
	mrb.define_method(st, color_class, "red", color_get_r, mrb.args_none())
	mrb.define_method(st, color_class, "blue", color_get_b, mrb.args_none())
	mrb.define_method(st, color_class, "green", color_get_g, mrb.args_none())
	mrb.define_method(st, color_class, "alpha", color_get_a, mrb.args_none())

	mrb.define_alias(st, color_class, "r", "red")
	mrb.define_alias(st, color_class, "b", "blue")
	mrb.define_alias(st, color_class, "g", "green")
	mrb.define_alias(st, color_class, "a", "alpha")

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
	mrb.define_class_method(st, draw_module, "measure_text", draw_measure_text, mrb.args_key(4, 0))

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

	as_class := mrb.define_class(st, "AssetSystem", mrb.state_get_object_class(st))
	mrb.define_class_method(st, as_class, "add_font", assets_add_font, mrb.args_req(1))
	mrb.define_class_method(st, as_class, "load_texture", assets_load_texture, mrb.args_req(1))
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
//// Textures
//////////////////////////////

setup_textures :: proc(st: ^mrb.State) {
	texture_asset_class := mrb.define_class(st, "Texture", mrb.state_get_object_class(st))
	mrb.set_data_type(texture_asset_class, .CData)
	mrb.define_method(st, texture_asset_class, "initialize", texture_init, mrb.args_req(1))
	engine_classes.texture_asset = texture_asset_class
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
	engine_classes.engine = engine_module
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
