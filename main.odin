package main

import "core:fmt"

import mrb "./mruby"

main :: proc() {

	state := mrb.open()
	defer mrb.close(state)

	mrb.show_copyright(state)
	mrb.show_version(state)

	mrb.load_string(state, "print 'Foo'")

	if mrb.state_get_exc(state) != nil {
		mrb.print_backtrace(state)
	}
	assert(mrb.state_get_exc(state) == nil, "No Exceptions expected")
}
