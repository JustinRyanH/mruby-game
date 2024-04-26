
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
	// IMPORTANT: even with manual GC, GC will sometimes happen on
	// new ruby objects. So you should copy it unless you plan
	// to consume this immediately
	//
	// NULL terminated C string from mrb_value
	string_cstr :: proc(state: ^State, str: Value) -> cstring ---
	// IMPORTANT: even with manual GC, GC will sometimes happen on
	// new ruby objects. So you should copy it unless you plan
	// to consume this immediately
	//
	// This will change str, to be a cstring behind the scenes
	string_value_cstr :: proc(state: ^State, str: ^Value) -> cstring ---

	// IMPORTANT: even with manual GC, GC will sometimes happen on
	// new ruby objects. So you should copy it unless you plan
	// to consume this immediately
	//
	// Returns a newly allocated C string from a Ruby string.
	// This is an utility function to pass a Ruby string to C library functions.
	//
	// - Returned string does not contain any NUL characters (but terminator).
	// - It raises an ArgumentError exception if Ruby string contains
	//   NUL characters.
	// - Returned string will be freed automatically on next GC.
	// - Caller can modify returned string without affecting Ruby string
	//   (e.g. it can be used for mkstemp(3)).
	//
	// @param mrb The current mruby state.
	// @param str Ruby string. Must be an instance of String.
	// @return A newly allocated C string.
	//
	str_to_cstr :: proc(state: ^State, str: Value) -> cstring ---
}
