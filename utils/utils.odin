package utils

import "core:hash"
import "core:strings"

generate_u64_from_string :: proc(s: string) -> u64 {
	return hash.murmur64b(transmute([]u8)s)
}


generate_u64_from_cstring :: proc(cs: cstring) -> u64 {
	s := strings.clone_from_cstring(cs, context.temp_allocator)
	return hash.murmur64b(transmute([]u8)s)
}
