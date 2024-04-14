package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
}

Value :: struct {
	v: u64,
}

State :: struct {}


// Function pointer type of custom allocator used in @see mrb_open_allocf.
//
// The function pointing it must behave similarly as realloc except:
// - If ptr is NULL it must allocate new space.
// - If size is zero, ptr must be freed.
//
// See @see mrb_default_allocf for the default implementation.
allocf :: #type proc "c" (state: ^State, ptr: rawptr, size: int, user_data: rawptr) -> rawptr

@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	// Creates new mrb_state.
	//
	// @return Pointer to the newly created mrb_state.
	open :: proc() -> ^State ---

	// Create new mrb_state with custom allocators.
	//
	// @param f
	//      Reference to the allocation function.
	// @param user_data
	//      User data will be passed to custom allocator f.
	//      If user data isn't required just pass NULL.
	// @return
	//      Pointer to the newly created mrb_state.
	//
	open_allocf :: proc(alloc: allocf, user_data: rawptr) -> ^State ---

	//
	// Create new mrb_state with just the mruby core
	//
	// @param f
	//      Reference to the allocation function.
	//      Use mrb_default_allocf for the default
	// @param user_data
	//      User data will be passed to custom allocator f.
	//      If user data isn't required just pass NULL.
	// @return
	//      Pointer to the newly created mrb_state.
	//
	open_core :: proc(alloc: allocf, user_data: rawptr) -> ^State ---
}
