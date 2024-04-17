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
	exc_inspect :: proc(state: ^State, exc: Value) -> Value ---
	exc_backtrace :: proc(state: ^State, exc: Value) -> Value ---
	get_backtrace :: proc(state: ^State) -> Value ---

	exc_mesg_set :: proc(state: ^State, exc: ^RException, mesg: Value) ---
	exc_mesg_get :: proc(state: ^State, exc: ^RException) -> Value ---
	f_raise :: proc(state: ^State, exc: Value) -> Value ---
	make_exception :: proc(state: ^State, exc: Value, mesg: Value) -> Value ---
}
