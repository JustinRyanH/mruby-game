package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
}


@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	load_string :: proc(mrb: ^State, s: cstring) -> Value ---
}
