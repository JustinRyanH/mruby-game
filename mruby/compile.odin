package mruby

import c "core:c/libc"

//  program load functions
// Please note! Currently due to interactions with the GC calling these functions will
// leak one RProc object per function call.
// To prevent this save the current memory arena before calling and restore the arena
// right after, like so
// int ai = mrb.gc_arena_save(mrb);
// status := mrb.load_string(mrb, buffer);
// mrb.gc_arena_restore(mrb, ai);


when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
}


ParserState :: struct {}
CompilerContext :: struct {}


@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	load_string :: proc(mrb: ^State, s: cstring) -> Value ---
	load_nstring :: proc(mrb: ^State, s: cstring, len: uint) -> Value ---
	load_string_ctx :: proc(mrb: ^State, s: cstring, ctx: ^CompilerContext) -> Value ---
	load_nstring_ctx :: proc(mrb: ^State, s: cstring, len: uint, ctx: ^CompilerContext) -> Value ---
}
