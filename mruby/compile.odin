package mruby

import c "core:c/libc"


when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
}


@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	load_string :: proc(mrb: ^State, s: cstring) -> Value ---
}
