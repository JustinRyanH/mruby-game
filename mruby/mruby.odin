package mruby

import "core:strings"

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
	foreign import compat "vendor/darwin/libmruby_compat.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
	foreign import compat "vendor/windows/mruby_compat.lib"
}

RBasic :: struct {}
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
	Array,
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

FiberState :: enum i32 {
	MRB_FIBER_CREATED = 0,
	MRB_FIBER_RUNNING,
	MRB_FIBER_RESUMED,
	MRB_FIBER_SUSPENDED,
	MRB_FIBER_TRANSFERRED,
	MRB_FIBER_TERMINATED,
}

Sym :: distinct u32
Code :: distinct u8


Aspec :: distinct u32


//
// Function takes n1 mandatory arguments and n2 optional arguments
//
// @param n1
//      The number of required arguments.
// @param n2
//      The number of optional arguments.
//
args :: proc(required: u32, optional: u32) -> Aspec {
	return args_req(required) | args_opt(optional)
}

CallInfo :: struct {}
Context :: struct {}

//
// Get keyword arguments by `mrb_get_args()` with `:` specifier.
//
// `mrb_kwargs::num` indicates that the total number of keyword values.
//
// `mrb_kwargs::required` indicates that the specified number of keywords starting from the beginning of the `mrb_sym` array are required.
//
// `mrb_kwargs::table` accepts a `mrb_sym` array of C.
//
// `mrb_kwargs::values` is an object array of C, and the keyword argument corresponding to the `mrb_sym` array is assigned.
// Note that `undef` is assigned if there is no keyword argument corresponding over `mrb_kwargs::required` to `mrb_kwargs::num`.
//
// `mrb_kwargs::rest` is the remaining keyword argument that can be accepted as `**rest` in Ruby.
// If `NULL` is specified, `ArgumentError` is raised when there is an undefined keyword.
//
// Examples:
//
//      // def method(a: 1, b: 2)
//
//      mrb_int kw_num = 2;
//      mrb_int kw_required = 0;
//      mrb_sym kw_names[] = { mrb_intern_lit(mrb, "a"), mrb_intern_lit(mrb, "b") };
//      mrb_value kw_values[kw_num];
//      mrb_kwargs kwargs = { kw_num, kw_required, kw_names, kw_values, NULL };
//
//      mrb_get_args(mrb, ":", &kwargs);
//      if (mrb_undef_p(kw_values[0])) { kw_values[0] = mrb_fixnum_value(1); }
//      if (mrb_undef_p(kw_values[1])) { kw_values[1] = mrb_fixnum_value(2); }
//
//
//      // def method(str, x:, y: 2, z: "default string", **opts)
//
//      mrb_value str, kw_rest;
//      uint32_t kw_num = 3;
//      uint32_t kw_required = 1;
//      // Note that `#include <mruby/presym.h>` is required beforehand because `MRB_SYM()` is used.
//      // If the usage of `MRB_SYM()` is not desired, replace it with `mrb_intern_lit()`.
//      mrb_sym kw_names[] = { MRB_SYM(x), MRB_SYM(y), MRB_SYM(z) };
//      mrb_value kw_values[kw_num];
//      mrb_kwargs kwargs = { kw_num, kw_required, kw_names, kw_values, &kw_rest };
//
//      mrb_get_args(mrb, "S:", &str, &kwargs);
//      // or: mrb_get_args(mrb, ":S", &kwargs, &str);
//      if (mrb_undef_p(kw_values[1])) { kw_values[1] = mrb_fixnum_value(2); }
//      if (mrb_undef_p(kw_values[2])) { kw_values[2] = mrb_str_new_cstr(mrb, "default string"); }
//
Kwargs :: struct {
	num:     int,
	require: int,
	table:   [^]Sym,
	values:  [^]Value,
	rest:    [^]Value,
}

Gc :: struct {}
ArenaIdx :: distinct i32

Value :: distinct uint

State :: struct {}


// Function pointer type of custom allocator used in @see mrb_open_allocf.
//
// The function pointing it must behave similarly as realloc except:
// - If ptr is NULL it must allocate new space.
// - If size is zero, ptr must be freed.
//
// See @see mrb_default_allocf for the default implementation.
allocf :: #type proc "c" (state: ^State, ptr: rawptr, size: uint, user_data: rawptr) -> rawptr

// Function pointer type for a function callable by mruby.
// 
// The arguments to the function are stored on the mrb_state. To get them see mrb_get_args
// 
// @param state The mruby state
// @param self The self object
// @return [mrb_value] The function's return value
MrbFunc :: #type proc "c" (state: ^State, value: Value) -> Value


// Converts a string into a symbol
sym_from_string :: proc "contextless" (state: ^State, str: string) -> Sym {
	data := raw_data(str)
	return intern(state, data, len(str))
}

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
	obj_id :: proc(obj: Value) -> i32 ---

	// TODO: Document
	obj_to_sym :: proc(state: ^State, name: Value) -> Sym ---

	// Kernel#p
	p :: proc(state: ^State, obj: ^RObject) ---

	// Object#eq
	obj_eq :: proc(state: ^State, a, b: Value) -> bool ---

	// TODO: Document
	obj_equal :: proc(state: ^State, a, b: Value) -> bool ---

	// TODO: Document
	equal :: proc(state: ^State, obj1, obj2: Value) -> bool ---

	// TODO: Document
	cmp :: proc(state: ^State, obj1, obj2: Value) -> i32 ---

	// Prints the Backtrace
	print_backtrace :: proc(state: ^State) ---
	// Prints the Error
	print_error :: proc(state: ^State) ---

	// Returns a symbol as a cstring
	// TODO: Figure out if this allocs?
	sym_name :: proc(state: ^State, sym: Sym) -> cstring ---

	// Returns a byte array to to turn into a proper `string`
	// TODO: Figure out if this allocs?
	sym_name_len :: proc(state: ^State, sym: Sym, len: ^i32) -> [^]u8 ---

	// Performs full GC
	garbage_collect :: proc(mrb: ^State) ---

	// Performs a heavy full gc
	full_gc :: proc(mrb: ^State) ---

	// Cleans up dead fresh items, Performs
	// a full_gc pass threshold
	incremental_gc :: proc(mrb: ^State) ---
}

sym_to_string :: proc(state: ^State, sym: Sym) -> string {
	len: i32

	data := sym_name_len(state, sym, &len)

	return strings.string_from_ptr(data, cast(int)len)
}

@(link_prefix = "mrb_c_")
@(default_calling_convention = "c")
foreign compat {
	// Gets the Exception from State
	// Returns nil if no error, otherwise error is on the RObject
	state_get_exc :: proc(mrb: ^State) -> ^RObject ---

	// Set an Exception on the State
	state_set_exec :: proc(mrb: ^State, exe: ^RObject) ---

	// Get a Reference to ruby global `self`
	state_get_top_self :: proc(mrb: ^State) -> ^RObject ---

	// Get a Reference to ruby `Object`
	state_get_object_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Class`
	state_get_class_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Module`
	state_get_module_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Proc`
	state_get_proc_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `String`
	state_get_string_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Array`
	state_get_array_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Hash`
	state_get_hash_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Range`
	state_get_range_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Float`
	state_get_float_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Integer`
	state_get_integer_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `True`
	state_get_true_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `False`
	state_get_false_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Nil`
	state_get_nil_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Symbol`
	state_get_symbol_class :: proc(mrb: ^State) -> ^RClass ---

	// Get a Reference to ruby `Kernel`
	state_get_kernel_module :: proc(mrb: ^State) -> ^RClass ---

	state_get_exception_class :: proc(mrb: ^State) -> ^RClass ---
	state_get_std_exception_class :: proc(mrb: ^State) -> ^RClass ---

	state_get_context :: proc(mrb: ^State) -> ^Context ---
	state_get_root_context :: proc(mrb: ^State) -> ^Context ---

	context_prev :: proc(mrb: ^Context) -> ^Context ---

	context_callinfo :: proc(mrb: ^Context) -> ^CallInfo ---

	context_fiber_state :: proc(mrb: ^Context) -> FiberState ---

	context_fiber :: proc(mrb: ^Context) -> ^RFiber ---

	// Saves the current arena location
	gc_arena_save :: proc(mrb: ^State) -> ArenaIdx ---

	// Sets the Arena Index
	gc_arena_restore :: proc(mrb: ^State, idx: ArenaIdx) ---


	// Get the current method sumbol
	//
	// Example:
	//     # Ruby style
	//     class Foo
	//       def bar
	//          puts __method__ # ":bar"
	//       end
	//     end
	get_mid :: proc(state: ^State) -> Sym ---

	// ARGs
	args_req :: proc(n: u32) -> Aspec ---
	args_opt :: proc(n: u32) -> Aspec ---
	args_rest :: proc() -> Aspec ---
	args_block :: proc() -> Aspec ---
	args_none :: proc() -> Aspec ---
	// keyword arguments (n of keys, kdict)
	args_key :: proc(nk: u32, kd: u32) -> Aspec ---


	set_data_type :: proc(c: ^RClass, t: VType) ---
}

@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	malloc :: proc(state: ^State, size: int) -> rawptr ---
	calloc :: proc(state: ^State, num, size: int) -> rawptr ---
	realloc :: proc(state: ^State, p: rawptr, size: int) -> rawptr ---
	realloc_simple :: proc(state: ^State, p: rawptr, size: int) -> rawptr ---
	obj_alloc :: proc(state: ^State, type: VType, class: ^RClass) -> ^RBasic ---
	free :: proc(state: ^State, p: rawptr) ---
}

@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {

	//  Format specifiers for {mrb_get_args} function
	//
	//  Must be a C string composed of the following format specifiers:
	//
	//  | char | Ruby type      | C types           | Notes                                              |
	//  |:----:|----------------|-------------------|----------------------------------------------------|
	//  | `o`  | {Object}       | {mrb_value}       | Could be used to retrieve any type of argument     |
	//  | `C`  | {Class}/{Module} | {mrb_value}     | when `!` follows, the value may be `nil`           |
	//  | `S`  | {String}       | {mrb_value}       | when `!` follows, the value may be `nil`           |
	//  | `A`  | {Array}        | {mrb_value}       | when `!` follows, the value may be `nil`           |
	//  | `H`  | {Hash}         | {mrb_value}       | when `!` follows, the value may be `nil`           |
	//  | `s`  | {String}       | const char *, {mrb_int} | Receive two arguments; `s!` gives (`NULL`,`0`) for `nil` |
	//  | `z`  | {String}       | const char *      | `NULL` terminated string; `z!` gives `NULL` for `nil` |
	//  | `a`  | {Array}        | const {mrb_value} *, {mrb_int} | Receive two arguments; `a!` gives (`NULL`,`0`) for `nil` |
	//  | `c`  | {Class}/{Module} | strcut RClass * | `c!` gives `NULL` for `nil`                        |
	//  | `f`  | {Integer}/{Float} | {mrb_float}    |                                                    |
	//  | `i`  | {Integer}/{Float} | {mrb_int}      |                                                    |
	//  | `b`  | boolean        | {mrb_bool}        |                                                    |
	//  | `n`  | {String}/{Symbol} | {mrb_sym}         |                                                    |
	//  | `d`  | data           | void *, {mrb_data_type} const | 2nd argument will be used to check data type so it won't be modified; when `!` follows, the value may be `nil` |
	//  | `I`  | inline struct  | void *, struct RClass | `I!` gives `NULL` for `nil`                    |
	//  | `&`  | block          | {mrb_value}       | &! raises exception if no block given.             |
	//  | `*`  | rest arguments | const {mrb_value} *, {mrb_int} | Receive the rest of arguments as an array; `*!` avoid copy of the stack.  |
	//  | <code>\|</code> | optional     |                   | After this spec following specs would be optional. |
	//  | `?`  | optional given | {mrb_bool}        | `TRUE` if preceding argument is given. Used to check optional argument is given. |
	//  | `:`  | keyword args   | {mrb_kwargs} const | Get keyword arguments. @see mrb_kwargs |
	//
	//
	// Retrieve arguments from mrb_state.
	//
	// @param mrb The current mruby state.
	// @param format is a list of format specifiers
	// @param ... The passing variadic arguments must be a pointer of retrieving type.
	// @return the number of arguments retrieved.
	// @see mrb_args_format
	// @see mrb_kwargs
	//
	get_args :: proc(state: ^State, format: cstring, #c_vararg args: ..any) -> i32 ---

	//
	// Defines a new class.
	//
	// If you're creating a gem it may look something like this:
	//
	// @param state The current mruby state.
	// @param name The name of the defined class.
	// @param super The new class parent.
	// @return Reference to the newly defined class.
	// 
	define_class :: proc(state: ^State, name: cstring, super: ^RClass) -> ^RClass ---
	define_class_id :: proc(state: ^State, name: Sym, super: ^RClass) -> ^RClass ---

	//
	//  Defines a new module.
	//
	//  @param State The current mruby state.
	//  @param name The name of the module.
	//  @return Reference to the newly defined module.
	define_module :: proc(state: ^State, name: cstring) -> ^RClass ---
	define_module_id :: proc(state: ^State, name: Sym) -> ^RClass ---

	//
	//  Returns the singleton class of an object.
	//
	//  Raises a `TypeError` exception for immediate values.
	//
	singleton_class :: proc(state: ^State, val: Value) -> Value ---

	//
	//  Returns the singleton class of an object.
	//
	//  Returns `nil` for immediate values,
	//
	singleton_class_ptr :: proc(state: ^State, val: Value) -> ^RClass ---

	//
	//Include a module in another class or module.
	//Equivalent to:
	//
	//  module B
	//    include A
	//  end
	//@param state The current mruby state.
	//@param class A reference to module or a class.
	//@param included A reference to the module to be included.
	include_module :: proc(state: ^State, class: ^RClass, included: ^RClass) ---

	//
	// Prepends a module in another class or module.
	//
	// Equivalent to:
	//  module B
	//    prepend A
	//  end
	// @param state The current mruby state.
	// @param class A reference to module or a class.
	// @param prepended A reference to the module to be prepended.
	//
	prepend_module :: proc(state: ^State, class: ^RClass, prepended: ^RClass) ---


	//
	// Defines a global function in ruby.
	// 
	// If you're creating a gem it may look something like this
	// 
	// Example: TODO:
	// 
	// @param state The mruby state reference.
	// @param class The class pointer where the method will be defined.
	// @param name The name of the method being defined.
	// @param func The function pointer to the method definition.
	// @param aspec The method parameters declaration.
	define_method :: proc(state: ^State, class: ^RClass, name: cstring, fn: MrbFunc, aspec: Aspec) ---
	define_method_id :: proc(state: ^State, class: ^RClass, sym: Sym, fn: MrbFunc, aspec: Aspec) ---


	//
	// Defines a class method.
	//
	// Example:
	//
	//     # Ruby style
	//     class Foo
	//       def Foo.bar
	//       end
	//     end
	//     // TODO: Odin Style
	//
	// @param mrb The mruby state reference.
	// @param cla The class where the class method will be defined.
	// @param name The name of the class method being defined.
	// @param fun The function pointer to the class method definition.
	// @param aspec The method parameters declaration.
	//
	define_class_method :: proc(state: ^State, class: ^RClass, name: cstring, fn: MrbFunc, aspec: Aspec) ---
	define_class_method_id :: proc(state: ^State, class: ^RClass, name: Sym, fn: MrbFunc, aspec: Aspec) ---

	// Gets an attribute off a class
	attr_get :: proc(state: ^State, obj: Value, id: Sym) -> Value ---

	// Checks if a class will respond to a call
	//
	// Example:
	//    #Ruby style
	//    foo = Bar.new
	//    assert(foo.respond_to?(:update), "Bar does have `update` method")
	respond_to :: proc(state: ^State, obj: Value, id: Sym) -> bool ---


	// a function to raise NotImplementedError with current method name
	notimplement :: proc(state: ^State) ---
	// a function to be replacement of unimplemented method
	notimplement_m :: proc(state: ^State, value: Value) -> Value ---

	//
	// Initialize a new object instance of c class.
	//
	// Example:
	//
	//     # Ruby style
	//     class ExampleClass
	//     end
	//
	//     p ExampleClass # => #<ExampleClass:0x9958588>
	//     // C style
	//     #include <stdio.h>
	//     #include <mruby.h>
	//
	//     void
	//     mrb_example_gem_init(mrb_state* mrb) {
	//       struct RClass *example_class;
	//       mrb_value obj;
	//       example_class = mrb_define_class(mrb, "ExampleClass", mrb->object_class); # => class ExampleClass; end
	//       obj = mrb_obj_new(mrb, example_class, 0, NULL); # => ExampleClass.new
	//       mrb_p(mrb, obj); // => Kernel#p
	//      }
	// @param state The current mruby state.
	// @param class Reference to the class of the new object.
	// @param argc Number of arguments in argv
	// @param argv Array of mrb_value to initialize the object
	// @return [mrb_value] The newly initialized object
	//
	obj_new :: proc(state: ^State, class: ^RClass, argc: uint, argv: [^]Value) -> Value ---

	//
	// Creates a new instance of Class, Class.
	//
	// Example:
	//
	//      mrb_example_gem_init :: proc(state: ^mrb.State) {
	//        example_class := class_new(state, mrb->object_class);
	//        obj := mrb.obj_new(state, example_class, 0, NULL); // => #<#<Class:0x9a945b8>:0x9a94588>
	//        mrb.p(mrb, obj); // => Kernel#p
	//      }
	//
	// @param state The current mruby state.
	// @param super The super class or parent.
	// @return [struct RClass *] Reference to the new class.
	//
	class_new :: proc(state: ^State, super: ^RClass) -> ^RClass ---

	str_new_cstr :: proc(state: ^State, cstr: cstring) -> Value ---
	str_new_static :: proc(state: ^State, p: [^]u8, len: uint) -> Value ---

	intern_cstr :: proc(state: ^State, cstr: cstring) -> Sym ---
	intern :: proc(state: ^State, rstr: [^]u8, size: uint) -> Sym ---

	// TODO: Implement
	// MRB_API mrb_bool mrb_obj_is_instance_of(mrb_state *mrb, mrb_value obj, struct RClass* c);
	// MRB_API mrb_bool mrb_func_basic_p(mrb_state *mrb, mrb_value obj, mrb_sym mid, mrb_func_t func);
}
