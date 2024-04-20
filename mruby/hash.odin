package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
	foreign import compat "vendor/darwin/libmruby_compat.a"
} else when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmt")
	foreign import lib "vendor/windows/libmruby.lib"
	foreign import compat "vendor/windows/mruby_compat.lib"
}
@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {

	// Initializes a new hash.
	//
	// Equivalent to:
	//
	//      Hash.new
	//
	hash_new :: proc(state: ^State) -> Value ---


	// Sets a keys and values to hashes.
	//
	// Equivalent to:
	//
	//      hash[key] = val
	hash_set :: proc(state: ^State, hash: Value, key: Value, v: Value) ---

	//
	// Gets a value from a key. If the key is not found, the default of the
	// hash is used.
	//
	// Equivalent to:
	//
	//     hash[key]
	hash_get :: proc(state: ^State, hash: Value, key: Value) -> Value ---

	//
	// Gets a value from a key. If the key is not found, the default parameter is
	// used.
	//
	// Equivalent to:
	//
	//     hash.key?(key) ? hash[key] : def
	hash_fetch :: proc(state: ^State, hash: Value, key: Value, default: Value) -> Value ---

	//
	// Deletes hash key and value pair.
	//
	// Equivalent to:
	//
	//     hash.delete(key)
	hash_delete_key :: proc(state: ^State, hash: Value, key: Value) -> Value ---

	//
	// Gets an array of keys.
	//
	// Equivalent to:
	//
	//     hash.keys
	hash_keys :: proc(state: ^State, hash: Value) -> Value ---

	//
	// Check if the hash has the key.
	//
	// Equivalent to:
	//
	//     hash.key?(key)
	hash_key_p :: proc(state: ^State, hash: Value, key: Value) -> bool ---


	//
	// Check if the hash is empty
	//
	// Equivalent to:
	//
	//     hash.empty?
	hash_empty_p :: proc(state: ^State, hash: Value) -> bool ---


	//
	// Clears the hash.
	//
	// Equivalent to:
	//
	//     hash.clear
	hash_clear :: proc(state: ^State, hash: Value) -> Value ---


	//
	// Get hash size.
	//
	// Equivalent to:
	//
	//      hash.size
	hash_size :: proc(state: ^State, hash: Value) -> Int ---


	//
	// Copies the hash. This function does NOT copy the instance variables
	// (except for the default value). Use mrb_obj_dup() to copy the instance
	// variables as well.
	hash_dup :: proc(state: ^State, hash: Value) -> Value ---

	//
	// Merges two hashes. The first hash will be modified by the
	// second hash.
	merge :: proc(state: ^State, a, b: Value) -> Value ---
}
