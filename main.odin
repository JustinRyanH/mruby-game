package main

import "core:fmt"

import mrb "./mruby"

main :: proc() {

	state := mrb.open()
	defer mrb.close(state)

	mrb.load_string(state, "puts 'Hello World'")

	fmt.println("Test")
}
