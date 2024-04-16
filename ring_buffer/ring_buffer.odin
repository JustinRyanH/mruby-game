package ring_buffer


RingBuffer :: struct($N: u32, $T: typeid) {
	index:  u32,
	length: u32,
	items:  [N]T,
}

append :: proc(rb: ^RingBuffer($N, $T), v: T) -> bool {
	if (length(rb) == N) {
		return false
	}


	index := (rb.index + rb.length) % N
	assert(index < N, "Out of Range Error, this is wrong")
	rb.items[index] = v
	rb.length += 1
	return true
}

pop :: proc(rb: ^RingBuffer($N, $T)) -> (val: T, empty: bool) {
	if (length(rb) == 0) {
		return
	}
	val = rb.items[rb.index]
	rb.index = ((rb.index + 1) % N)
	rb.length -= 1

	return val, true
}

length :: proc(rb: ^RingBuffer($N, $T)) -> u32 {
	return rb.length
}
