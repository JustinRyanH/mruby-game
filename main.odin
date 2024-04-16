package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:runtime"
import "core:strings"

import mrb "./mruby"

Game :: struct {
	f: f64,
}

FishData :: struct {
	name: cstring,
}


fish_free: mrb.DataType = {"Fish", mrb.free}

fish_init :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = runtime.default_context()

	name: cstring
	mrb.get_args(state, "z", &name)
	fmt.println("name", name)
	foo: ^FishData = cast(^FishData)mrb.rdata_data(self)
	if (foo != nil) {
		mrb.free(state, foo)
	}
	mrb.data_init(self, nil, &fish_free)
	foo = cast(^FishData)mrb.malloc(state, size_of(FishData))
	foo.name = name
	mrb.data_init(self, foo, &fish_free)


	return self
}

fish_name :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	foo: ^FishData = cast(^FishData)mrb.rdata_data(self)
	return mrb.str_new_cstr(state, foo.name)
}

mrb_rawr :: proc "c" (state: ^mrb.State, value: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	test_str: cstring
	res := mrb.get_args(state, "z", &test_str)
	fmt.println("res", res)

	return mrb.float_value(state, g.f)
}

g: ^Game

main :: proc() {
	g = new(Game)
	defer free(g)
	state := mrb.open()
	defer mrb.close(state)

	mrb.show_copyright(state)
	mrb.show_version(state)

	mrb.load_string(state, "puts 'foo'")
	assert(mrb.state_get_exc(state) == nil, "No Exceptions expected")

	fish_class := mrb.define_class(state, "Fish", mrb.state_get_object_class(state))
	mrb.define_method(state, fish_class, "initialize", fish_init, mrb.args_req(1))
	mrb.define_method(state, fish_class, "name", fish_init, mrb.args_none())

	mrb.load_string(state, "Fish.new('\"fish foo\"')")

	if mrb.state_get_exc(state) != nil {
		mrb.print_backtrace(state)
	}
}
