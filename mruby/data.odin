package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
	foreign import compat "vendor/darwin/libmruby_compat.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
	foreign import compat "vendor/windows/mruby_compat.lib"
}


// typedef struct mrb_data_type {
//   /** data type name */
//   const char *struct_name;
// 
//   /** data type release function pointer */
//   void (*dfree)(mrb_state *mrb, void*);
// } mrb_data_type;
DataType :: struct {
	struct_name: cstring,
	free:        proc "c" (state: ^State, data: rawptr),
}


@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	data_object_alloc :: proc(state: ^State, class: ^RClass, data: rawptr, type: VType) -> ^RData ---
}

@(link_prefix = "mrb_c_")
@(default_calling_convention = "c")
foreign compat {
	data_init :: proc(v: Value, p: rawptr, dt: ^DataType) ---
	rdata_data :: proc(d: Value) -> rawptr ---
	data_type :: proc(d: Value) -> DataType ---
}
