package mruby

import c "core:c/libc"

//  program load functions
// Please note! Currently due to interactions with the GC calling these functions will
// leak one RProc object per function call.
// To prevent this save the current memory arena before calling and restore the arena
// right after, like so
// ai = mrb.gc_arena_save(mrb);
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

load_cstring :: proc(state: ^State, s: cstring) -> Value {
	ctx := state_get_context(state)
	ai := gc_arena_save(ctx)
	defer gc_arena_restore(ctx, ai)

	return mrb_load_string(state, s)
}

load_string :: proc(state: ^State, s: string) -> Value {
	ctx := state_get_context(state)
	ai := gc_arena_save(ctx)
	defer gc_arena_restore(ctx, ai)

	return mrb_load_nstring(state, raw_data(s), len(s))
}


@(private)
@(default_calling_convention = "c")
foreign lib {
	mrb_load_string :: proc(mrb: ^State, s: cstring) -> Value ---
	mrb_load_nstring :: proc(mrb: ^State, s: [^]u8, len: uint) -> Value ---
	mrb_load_string_ctx :: proc(mrb: ^State, s: cstring, ctx: ^CompilerContext) -> Value ---
	mrb_load_nstring_ctx :: proc(mrb: ^State, s: [^]u8, len: uint, ctx: ^CompilerContext) -> Value ---
}
