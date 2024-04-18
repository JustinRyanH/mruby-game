package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
}

@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {

	//
	// Get a global variable. Will return nil if the var does not exist
	//
	// Example:
	//
	//     !!!ruby
	//     # Ruby style
	//     var = $value
	//
	//     !!!c
	//     // C style
	//     mrb_sym sym = mrb_intern_lit(mrb, "$value");
	//     mrb_value var = mrb_gv_get(mrb, sym);
	//
	// @param mrb The mruby state reference
	// @param sym The name of the global variable
	// @return The value of that global variable. May be nil
	//
	gv_get :: proc(state: ^State, sym: Sym) -> Value ---

	//
	// Set a global variable
	//
	// Example:
	//
	//     !!!ruby
	//     # Ruby style
	//     $value = "foo"
	//
	//     !!!c
	//     // C style
	//     mrb_sym sym = mrb_intern_lit(mrb, "$value");
	//     mrb_gv_set(mrb, sym, mrb_str_new_lit("foo"));
	//
	// @param mrb The mruby state reference
	// @param sym The name of the global variable
	// @param val The value of the global variable
	gv_set :: proc(state: ^State, sym: Sym, v: Value) ---

	//
	//Remove a global variable.
	//
	//Example:
	//
	//    # Ruby style
	//    $value = nil
	//
	//    // C style
	//    mrb_sym sym = mrb_intern_lit(mrb, "$value");
	//    mrb_gv_remove(mrb, sym);
	//
	//@param mrb The mruby state reference
	//@param sym The name of the global variable
	//
	gv_remove :: proc(state: ^State, sym: Sym) ---
}
