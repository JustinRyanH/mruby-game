package mruby

when ODIN_OS == .Darwin {
	when ODIN_ARCH == .arm64 {
		foreign import compat "vendor/darwin/libmruby_compat.a"
	}
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import compat "vendor/windows/mruby_compat.lib"
}

GcState :: enum i32 {
	Root = 0,
	Mark,
	Sweep,
}

@(link_prefix = "mrb_c_")
@(default_calling_convention = "c")
foreign compat {
	gc_get_live :: proc(state: ^State) -> uint ---
	gc_get_live_after_mark :: proc(state: ^State) -> uint ---
	gc_get_state :: proc(state: ^State) -> GcState ---
	gc_mark_value :: proc(state: ^State, v: Value) ---
	gc_get_threshold :: proc(state: ^State) -> uint ---
}
