package mruby

import c "core:c/libc"
import "core:fmt"

//  program load functions
// Please note! Currently due to interactions with the GC calling these functions will
// leak one RProc object per function call.
// To prevent this save the current memory arena before calling and restore the arena
// right after, like so
// ai = mrb.gc_arena_save(mrb);
// status := mrb.load_string(mrb, buffer);
// mrb.gc_arena_restore(mrb, ai);


when ODIN_OS == .Darwin {
	when ODIN_ARCH == .arm64 {
		foreign import lib "vendor/darwin/arm/libmruby.a"
	} else when ODIN_ARCH == .amd64 {
		foreign import lib "vendor/darwin/amd/libmruby.a"
	}
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
}


ParserState :: struct {}
CompilerContext :: struct {}

load_cstring :: proc(state: ^State, s: cstring) -> Value {
	ai := gc_arena_save(state)
	defer gc_arena_restore(state, ai)

	return mrb_load_string(state, s)
}

load_string :: proc(state: ^State, s: string) -> Value {
	ai := gc_arena_save(state)
	v := mrb_load_nstring(state, raw_data(s), len(s))
	gc_arena_restore(state, ai)

	return v
}


@(private)
@(default_calling_convention = "c")
foreign lib {
	mrb_load_string :: proc(mrb: ^State, s: cstring) -> Value ---
	mrb_load_nstring :: proc(mrb: ^State, s: [^]u8, len: uint) -> Value ---
	mrb_load_string_ctx :: proc(mrb: ^State, s: cstring, ctx: ^CompilerContext) -> Value ---
	mrb_load_nstring_ctx :: proc(mrb: ^State, s: [^]u8, len: uint, ctx: ^CompilerContext) -> Value ---
}
