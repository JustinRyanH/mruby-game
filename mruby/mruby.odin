package mruby

import c "core:c/libc"

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
	foreign import compat "vendor/windows/mruby_compat.lib"
}

#assert(size_of(c.int) == size_of(i32))


RFloat :: struct {}
RInteger :: struct {}
RCptr :: struct {}
RObject :: struct {}
RClass :: struct {}
RProc :: struct {}
RArray :: struct {}
RHash :: struct {}
RString :: struct {}
RRange :: struct {}
RException :: struct {}
REnv :: struct {}
RData :: struct {}
RFiber :: struct {}
RIStruct :: struct {}
RBreak :: struct {}
RComplex :: struct {}
RRational :: struct {}
RBigInt :: struct {}

VType :: enum i32 {
	False,
	True,
	Symbol,
	Undef,
	Free,
	Float,
	Integer,
	Cptr,
	Object,
	Class,
	Module,
	IClass,
	SClass,
	Proc,
	Hash,
	String,
	Range,
	Exception,
	Env,
	CData,
	Fiber,
	Struct,
	IStruct,
	Break,
	Complex,
	Rational,
	BigInt,
}

Sym :: distinct u32
Code :: distinct u8

CallInfo :: struct {}
Context :: struct {}

Value :: struct {
	v: uintptr,
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

	//
	// Closes and frees a mrb_state.
	//
	// @param state
	//      Pointer to the mrb_state to be closed.
	//
	close :: proc(state: ^State) ---

	// Displays copyright of mruby to stdout
	//
	// @param state
	//      Pointer to the mrb_state to be closed.
	show_copyright :: proc(state: ^State) ---

	// Displays mruby version of mruby to stdout
	//
	// @param state
	//      Pointer to the mrb_state to be closed.
	show_version :: proc(state: ^State) ---

	// TODO: Document
	p :: proc(state: ^State, v: Value) ---

	// TODO: Document
	obj_id :: proc(obj: Value) -> i32 ---

	// TODO: Document
	obj_to_sym :: proc(state: ^State, name: Value) -> Sym ---

	// TODO: Document
	obj_eq :: proc(state: ^State, a, b: Value) -> bool ---

	// TODO: Document
	obj_equal :: proc(state: ^State, a, b: Value) -> bool ---

	// TODO: Document
	equal :: proc(state: ^State, obj1, obj2: Value) -> bool ---

	// TODO: Document
	cmp :: proc(state: ^State, obj1, obj2: Value) -> i32 ---

	// TODO: Implement - GC
	// #define mrb_gc_arena_save(mrb) ((mrb)->gc.arena_idx)
	//#define mrb_gc_arena_restore(mrb, idx) ((mrb)->gc.arena_idx = (idx))

	// Prints the Backtrace
	print_backtrace :: proc(state: ^State) ---
	// Prints the Error
	print_error :: proc(state: ^State) ---
}

@(link_prefix = "mrb_c_")
@(default_calling_convention = "c")
foreign compat {
	state_get_exc :: proc(mrb: ^State) -> ^RObject ---
}
