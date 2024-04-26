package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

import mrb "./mruby"


setup_require :: proc(state: ^mrb.State) {
	krn := mrb.state_get_kernel_module(state)


	mrb.define_method(state, krn, "require", require_fn, mrb.args_req(1))
}


load_ruby_file :: proc(as: ^AssetSystem, path: string) -> (string, bool) {
	rel_path, err := filepath.rel("assets/", path, context.temp_allocator)
	assert(err == .None)
	ruby_path := strings.concatenate({rel_path, ".rb"}, context.temp_allocator)
	full_path := filepath.join({as.asset_dir, ruby_path}, context.temp_allocator)
	if !os.exists(full_path) {
		return string{}, false
	}
	return full_path, true
}

require_fn :: proc "c" (state: ^mrb.State, self: mrb.Value) -> mrb.Value {
	context = load_context(state)

	filename: mrb.Value

	mrb.get_args(state, "o", &filename)

	path, success := mrb.string_from_value(state, filename, context.temp_allocator)
	if !success {
		return mrb.false_value()
	}

	as := &g.assets
	if !os.exists(as.asset_dir) {
		mrb.raise_exception(state, "%s is not a valid asset directory", as.asset_dir)
	}

	rbf, rbf_found := load_ruby_file(as, path)

	if rbf_found {
		handle, rbf_loaded := asset_system_load_ruby(as, rbf)
		if !success {mrb.raise_exception(state, "Could not load Ruby Script: %s", rbf)}
		game_run_code(g, handle)

	}


	return mrb.true_value()
}
