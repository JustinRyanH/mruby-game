package mruby

when ODIN_OS == .Darwin {
	when ODIN_ARCH == .arm64 {
		foreign import compat "vendor/darwin/arm/libmruby_compat.a"
	} else when ODIN_ARCH == .amd64 {
		foreign import compat "vendor/darwin/amd/libmruby_compat.a"
	}
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
	float_value :: proc(state: ^State, f: Float) -> Value ---
	cptr_value :: proc(state: ^State, p: rawptr) -> Value ---
	int_value :: proc(state: ^State, i: Int) -> Value ---
	fix_num_value :: proc(i: Int) -> Value ---
	symbol_value :: proc(i: Sym) -> Value ---
	false_value :: proc() -> Value ---
	true_value :: proc() -> Value ---
	bool_value :: proc(b: bool) -> Value ---

	nil_value :: proc() -> Value ---
	obj_value :: proc(p: rawptr) -> Value ---
	undef_value :: proc() -> Value ---

	immediate_p :: proc(v: Value) -> bool ---
	integer_p :: proc(v: Value) -> bool ---
	fixnum_p :: proc(v: Value) -> bool ---
	symbol_p :: proc(v: Value) -> bool ---
	undef_p :: proc(v: Value) -> bool ---
	nil_p :: proc(v: Value) -> bool ---
	false_p :: proc(v: Value) -> bool ---
	true_p :: proc(v: Value) -> bool ---
	float_p :: proc(v: Value) -> bool ---
	array_p :: proc(v: Value) -> bool ---
	string_p :: proc(v: Value) -> bool ---
	hash_p :: proc(v: Value) -> bool ---
	cptr_p :: proc(v: Value) -> bool ---
	exception_p :: proc(v: Value) -> bool ---
	free_p :: proc(v: Value) -> bool ---
	object_p :: proc(v: Value) -> bool ---
	class_p :: proc(v: Value) -> bool ---
	module_p :: proc(v: Value) -> bool ---
	iclass_p :: proc(v: Value) -> bool ---
	sclass_p :: proc(v: Value) -> bool ---
	proc_p :: proc(v: Value) -> bool ---
	range_p :: proc(v: Value) -> bool ---
	env_p :: proc(v: Value) -> bool ---
	data_p :: proc(v: Value) -> bool ---
	fiber_p :: proc(v: Value) -> bool ---
	istruct_p :: proc(v: Value) -> bool ---
	break_p :: proc(v: Value) -> bool ---
}
