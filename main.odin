package main

import "core:fmt"
import "core:math"
import "core:runtime"

import mrb "./mruby"

Game :: struct {
	f: f64,
}

mrb_rawr :: proc "c" (state: ^mrb.State, value: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	// test_cstr: f32 = 0
	// res := mrb.get_args(state, "f", &test_cstr)
	// fmt.println("test_cstr", test_cstr)

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

	kernel := mrb.state_get_kernel_module(state)
	foo_class := mrb.define_class(state, "Foo", mrb.state_get_object_class(state))

	mrb.define_method(state, foo_class, "rawr", mrb_rawr, mrb.args(1, 0))

	mrb.load_string(state, `
    $a = Foo.new
    puts $a.rawr(30)
  `)

	g.f = math.PI

	mrb.load_string(state, `
    puts $a.rawr(10)
  `)


	if mrb.state_get_exc(state) != nil {
		mrb.print_backtrace(state)
	}
}
