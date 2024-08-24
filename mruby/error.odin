package mruby

import "core:fmt"

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

raise_exception :: proc(state: ^State, msg: string, args: ..any) {
	exception_class := state_get_exception_class(state)
	err_msg := fmt.ctprintf(msg, ..args)
	raise(state, exception_class, err_msg)

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


	raise :: proc(state: ^State, class: ^RClass, msg: cstring) ---
}


// MRB_API mrb_value mrb_exc_new(mrb_state *mrb, struct RClass *c, const char *ptr, mrb_int len);
// MRB_API mrb_noreturn void mrb_exc_raise(mrb_state *mrb, mrb_value exc);
// 
// MRB_API mrb_noreturn void mrb_raise(mrb_state *mrb, struct RClass *c, const char *msg);
// MRB_API mrb_noreturn void mrb_raisef(mrb_state *mrb, struct RClass *c, const char *fmt, ...);
// MRB_API mrb_noreturn void mrb_name_error(mrb_state *mrb, mrb_sym id, const char *fmt, ...);
// MRB_API mrb_noreturn void mrb_frozen_error(mrb_state *mrb, void *frozen_obj);
// MRB_API mrb_noreturn void mrb_argnum_error(mrb_state *mrb, mrb_int argc, int min, int max);
