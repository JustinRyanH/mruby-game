package main

import "core:fmt"

import mrb "./mruby"

main :: proc() {

	state := mrb.open()

	mrb.load_string(state, "puts 'Hello World'")

	fmt.println("Test")
}
