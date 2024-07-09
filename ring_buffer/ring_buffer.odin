package ring_buffer


RingBuffer :: struct($N: u32, $T: typeid) {
	index:  u32,
	length: u32,
	items:  [N]T,
}

RingBufferIterator :: struct($N: u32, $T: typeid) {
	rb:     ^RingBuffer(N, T),
	index:  u32,
	length: u32,
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

// Appends the RingBuffer, and overwrites the first element
append_overwrite :: proc(rb: ^RingBuffer($N, $T), v: T) {
	if (length(rb) == N) {
		index := (rb.index + rb.length) % N
		rb.items[index] = v
		rb.index = (rb.index + 1) % N
		return
	}
	append(rb, v)
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

new_iter :: proc "contextless" (rb: ^RingBuffer($N, $T)) -> RingBufferIterator(N, T) {
	return RingBufferIterator(N, T){rb = rb, index = rb.index, length = 0}
}

iter_next :: proc "contextless" (iter: ^RingBufferIterator($N, $T)) -> (value: T, has_more: bool) {
	if iter.rb.length == 0 {
		return
	}
	index := (iter.index + iter.length) % N
	value = iter.rb.items[index]
	has_more = iter.length != iter.rb.length

	iter.length += 1
	return
}
