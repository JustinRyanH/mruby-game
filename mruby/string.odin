
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
	// NULL terminated C string from mrb_value
	string_cstr :: proc(state: ^State, str: Value) -> cstring ---
	// This will change str, to be a cstring behind the scenes
	string_value_cstr :: proc(state: ^State, str: ^Value) -> cstring ---

}
