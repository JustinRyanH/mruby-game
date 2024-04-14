package main

import "core:fmt"

import mrb "./mruby"

main :: proc() {

	state := mrb.open()
	defer mrb.close(state)

	mrb.show_copyright(state)
	mrb.show_version(state)

	mrb.load_string(state, "puts 'Hello World'")
	assert(mrb.state_get_exc(state) == nil, "No Exceptions for Hello World")

	fmt.println("Test")
}
