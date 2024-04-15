package mruby

when ODIN_OS == .Darwin {
	foreign import compat "vendor/darwin/libmruby_compat.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import compat "vendor/windows/mruby_compat.lib"
}


// TODO: Figure out how the Value is packed in, and do the work here instead of compat
//
// mrb_value representation:
//
// 64bit word with inline float:
//   nil   : ...0000 0000 (all bits are 0)
//   false : ...0000 0100 (mrb_fixnum(v) != 0)
//   true  : ...0000 1100
//   undef : ...0001 0100
//   symbol: ...0001 1100 (use only upper 32-bit as symbol value with MRB_64BIT)
//   fixnum: ...IIII III1
//   float : ...FFFF FF10 (51 bit significands; require MRB_64BIT)
//   object: ...PPPP P000
@(link_prefix = "mrb_c_")
@(default_calling_convention = "c")
foreign compat {
	float_value :: proc(state: ^State, f: f64) -> Value ---
	cptr_value :: proc(state: ^State, p: rawptr) -> Value ---
	int_value :: proc(state: ^State, i: int) -> Value ---
	fix_num_value :: proc(i: int) -> Value ---
	symbol_value :: proc(i: Sym) -> Value ---
	false_value :: proc() -> Value ---
	true_value :: proc() -> Value ---
	bool_value :: proc(b: bool) -> Value ---

	nil_value :: proc() -> Value ---
	obj_value :: proc(p: rawptr) -> Value ---
	undef_value :: proc() -> Value ---
}