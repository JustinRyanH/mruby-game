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
	// /*
	//  * Concatenate two arrays. The target array will be modified
	//  *
	//  * Equivalent to:
	//  *      ary.concat(other)
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param self The target array.
	//  * @param other The array that will be concatenated to self.
	//  */
	// MRB_API void mrb_ary_concat(mrb_state *mrb, mrb_value self, mrb_value other);
	// 
	// /*
	//  * Create an array from the input. It tries calling to_a on the
	//  * value. If value does not respond to that, it creates a new
	//  * array with just this value.
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param value The value to change into an array.
	//  * @return An array representation of value.
	//  */
	// MRB_API mrb_value mrb_ary_splat(mrb_state *mrb, mrb_value value);
	// 
	// /*
	//  * Pushes value into array.
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary << value
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param ary The array in which the value will be pushed
	//  * @param value The value to be pushed into array
	//  */
	// MRB_API void mrb_ary_push(mrb_state *mrb, mrb_value array, mrb_value value);
	// 
	// /*
	//  * Pops the last element from the array.
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary.pop
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param ary The array from which the value will be popped.
	//  * @return The popped value.
	//  */
	// MRB_API mrb_value mrb_ary_pop(mrb_state *mrb, mrb_value ary);
	// 
	// /*
	//  * Sets a value on an array at the given index
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary[n] = val
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param ary The target array.
	//  * @param n The array index being referenced.
	//  * @param val The value being set.
	//  */
	// MRB_API void mrb_ary_set(mrb_state *mrb, mrb_value ary, mrb_int n, mrb_value val);
	// 
	// /*
	//  * Replace the array with another array
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary.replace(other)
	//  *
	//  * @param mrb The mruby state reference
	//  * @param self The target array.
	//  * @param other The array to replace it with.
	//  */
	// MRB_API void mrb_ary_replace(mrb_state *mrb, mrb_value self, mrb_value other);
	// 
	// /*
	//  * Unshift an element into the array
	//  *
	//  * Equivalent to:
	//  *
	//  *     ary.unshift(item)
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param self The target array.
	//  * @param item The item to unshift.
	//  */
	// MRB_API mrb_value mrb_ary_unshift(mrb_state *mrb, mrb_value self, mrb_value item);
	// 
	// /*
	//  * Get nth element in the array
	//  *
	//  * Equivalent to:
	//  *
	//  *     ary[offset]
	//  *
	//  * @param ary The target array.
	//  * @param offset The element position (negative counts from the tail).
	//  */
	// MRB_API mrb_value mrb_ary_entry(mrb_value ary, mrb_int offset);
	// #define mrb_ary_ref(mrb, ary, n) mrb_ary_entry(ary, n)
	// 
	// /*
	//  * Replace subsequence of an array.
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary[head, len] = rpl
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param self The array from which the value will be partiality replaced.
	//  * @param head Beginning position of a replacement subsequence.
	//  * @param len Length of a replacement subsequence.
	//  * @param rpl The array of replacement elements.
	//  *            It is possible to pass `mrb_undef_value()` instead of an empty array.
	//  * @return The receiver array.
	//  */
	// MRB_API mrb_value mrb_ary_splice(mrb_state *mrb, mrb_value self, mrb_int head, mrb_int len, mrb_value rpl);
	// 
	// /*
	//  * Shifts the first element from the array.
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary.shift
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param self The array from which the value will be shifted.
	//  * @return The shifted value.
	//  */
	// MRB_API mrb_value mrb_ary_shift(mrb_state *mrb, mrb_value self);
	// 
	// /*
	//  * Removes all elements from the array
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary.clear
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param self The target array.
	//  * @return self
	//  */
	// MRB_API mrb_value mrb_ary_clear(mrb_state *mrb, mrb_value self);
	// 
	// /*
	//  * Join the array elements together in a string
	//  *
	//  * Equivalent to:
	//  *
	//  *      ary.join(sep="")
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param ary The target array
	//  * @param sep The separator, can be NULL
	//  */
	// MRB_API mrb_value mrb_ary_join(mrb_state *mrb, mrb_value ary, mrb_value sep);
	// 
	// /*
	//  * Update the capacity of the array
	//  *
	//  * @param mrb The mruby state reference.
	//  * @param ary The target array.
	//  * @param new_len The new capacity of the array
	//  */
	// MRB_API mrb_value mrb_ary_resize(mrb_state *mrb, mrb_value ary, mrb_int new_len);
}
