package main

import "core:fmt"
import "core:runtime"

import mrb "./mruby"

Game :: struct {
	f: f32,
}

mrb_rawr :: proc "c" (state: ^mrb.State, value: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	return mrb.float_value(state, 13.5)
}

main :: proc() {

	state := mrb.open()
	defer mrb.close(state)

	mrb.show_copyright(state)
	mrb.show_version(state)

	mrb.load_string(state, "puts 'foo'")
	assert(mrb.state_get_exc(state) == nil, "No Exceptions expected")

	kernel := mrb.state_get_kernel_module(state)
	foo_class := mrb.define_class(state, "Foo", mrb.state_get_object_class(state))

	mrb.define_method(state, foo_class, "rawr", mrb_rawr, 0)
	mrb.load_string(state, `
    a = Foo.new
    puts a.rawr
  `)


	if mrb.state_get_exc(state) != nil {
		mrb.print_backtrace(state)
	}
}
