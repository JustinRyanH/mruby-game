package main

import "core:fmt"

import mrb "./mruby"
import rl "vendor:raylib"


setup_require :: proc(state: ^mrb.State) {
	krn := mrb.state_get_kernel_module(state)


	mrb.define_method(state, krn, "require", require_fn, mrb.args_req(1))
}

require_fn :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	filename: mrb.Value

	mrb.get_args(state, "o", &filename)

	path, success := mrb.cstring_from_value(state, filename)
	if !success {
		return mrb.false_value()
	}
	defer delete(path)

	fmt.println("Loading Path: ", path)

	cwd := rl.GetWorkingDirectory()

	ruby_files := rl.LoadDirectoryFilesEx(cwd, "*.rb", true)
	fmt.println(ruby_files.capacity, ruby_files.count)

	return mrb.true_value()
}
