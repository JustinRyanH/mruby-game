package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
}
@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	//
	// Initializes a new array.
	//
	// Equivalent to:
	//
	//      Array.new
	//
	ary_new :: proc(state: ^State) -> Value ---


	//
	// Initializes a new array with initial values
	//
	// Equivalent to:
	//
	//      Array[value1, value2, ...]
	//
	ary_new_from_values :: proc(state: ^State, size: Int, values: [^]Value) -> Value ---


	//
	// Initializes a new array with two initial values
	//
	// Equivalent to:
	//
	//      Array[car, cdr]
	//
	assoc_new :: proc(state: ^State, car: Value, cdr: Value) -> Value ---

	//
	// Concatenate two arrays. The target array will be modified
	//
	// Equivalent to:
	//      ary.concat(other)
	//
	ary_concat :: proc(state: ^State, self: Value, other: Value) ---


	//
	// Create an array from the input. It tries calling to_a on the
	// value. If value does not respond to that, it creates a new
	// array with just this value.
	ary_splat :: proc(state: ^State, value: Value) -> Value ---


	//
	// Pushes value into array.
	//
	// Equivalent to:
	//
	//      ary << value
	//
	ary_push :: proc(state: ^State, array: Value, value: Value) ---


	//
	// Pops the last element from the array.
	//
	// Equivalent to:
	//
	//      ary.pop
	//
	ary_pop :: proc(state: ^State, array: Value) -> Value ---


	//
	// Sets a value on an array at the given index
	//
	// Equivalent to:
	//
	//      ary[n] = val
	//
	ary_set :: proc(state: ^State, array: Value, index: Value, value: Value) ---


	//
	// Replace the array with another array
	//
	// Equivalent to:
	//
	//      ary.replace(other)
	//
	ary_replace :: proc(state: ^State, self: Value, other: Value) ---

	//
	// Unshift an element into the array
	//
	// Equivalent to:
	//
	//     ary.unshift(item)
	//
	ary_unshift :: proc(state: ^State, self: Value, item: Value) -> Value ---

	//
	// Get nth element in the array
	//
	// Equivalent to:
	//
	//     array[offset]
	//
	ary_entry :: proc(array: Value, offset: Int) -> Value ---

	//
	// Replace subsequence of an array.
	//
	// Equivalent to:
	//
	//      ary[head, len] = rpl
	//
	ary_splice :: proc(state: ^State, self: Value, head: int, len: int, replace_array: Value) -> Value ---

	// Shifts the first element from the array.
	//
	// Equivalent to:
	//
	//      ary.shift
	//
	ary_shift :: proc(state: ^State, self: Value) -> Value ---

	// 
	// Removes all elements from the array
	//
	// Equivalent to:
	//
	//      ary.clear
	//
	ary_clear :: proc(state: ^State, self: Value) -> Value ---

	// Join the array elements together in a string
	//
	// Equivalent to:
	//
	//      ary.join(sep="")
	//
	ary_join :: proc(state: ^State, array: Value, sep: Value) -> Value ---

	//
	// Update the capacity of the array
	//
	ary_resize :: proc(state: ^State, array: Value, size: Int) -> Value ---
}
