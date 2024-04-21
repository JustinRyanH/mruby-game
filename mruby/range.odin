package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
	foreign import compat "vendor/darwin/mruby_compat.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
	foreign import compat "vendor/windows/mruby_compat.lib"
}

RangeEdges :: struct {
	beginning: Value,
	end:       Value,
}


// Parses a Range assuming the high and low is a mrb.Int
parse_range_int :: proc "contextless" (
	state: ^State,
	rng: ^RRange,
) -> (
	low, high: Int,
	exclusive: bool,
) {

	low_v := range_beg(rng)
	high_v := range_end(rng)

	low = as_int(state, low_v)
	high = as_int(state, high_v)

	if low > high {
		low, high = high, low
	}

	exclusive = range_excl(rng)
	return
}


// RangeError :: enum i32 {
// 	TypeMismatch = 0,
// 	Ok           = 1,
// 	Out          = 2,
// }

@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	range_ptr :: proc(state: ^State, range: Value) -> ^RRange ---
	range_new :: proc(state: ^State, start, end: Value, exclude: bool) -> Value ---
	// MRB_API enum mrb_range_beg_len mrb_range_beg_len(mrb_state *mrb, mrb_value range, mrb_int *begp, mrb_int *lenp, mrb_int len, mrb_bool trunc);
}

@(link_prefix = "mrb_c_")
@(default_calling_convention = "c")
foreign compat {
	range_beg :: proc(r: ^RRange) -> Value ---
	range_end :: proc(r: ^RRange) -> Value ---
	range_excl :: proc(r: ^RRange) -> bool ---
}
