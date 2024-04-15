package main

import "core:fmt"
import "core:runtime"

import mrb "./mruby"

mrb_rawr :: proc "c" (state: ^mrb.State, value: mrb.Value) -> mrb.Value {
	context = runtime.default_context()
	v := mrb.float_value(state, 1)
	fmt.printf("%b", v)


	return v
}

main :: proc() {

	state := mrb.open()
	defer mrb.close(state)

	mrb.show_copyright(state)
	mrb.show_version(state)

	mrb.load_string(state, "puts 'foo'")
	assert(mrb.state_get_exc(state) == nil, "No Exceptions expected")

	kernel := mrb.state_get_kernel_module(state)
	mrb.define_method(state, kernel, "rawr", mrb_rawr, 0)
	mrb.load_string(state, "puts rawr.class")


	if mrb.state_get_exc(state) != nil {
		mrb.print_backtrace(state)
	}
}
