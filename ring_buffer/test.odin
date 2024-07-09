package ring_buffer

import "core:fmt"
import "core:math"
import "core:testing"

/////////////////////////////
// Tests
/////////////////////////////

@(test)
test_ring_buffer :: proc(t: ^testing.T) {
	using testing

	ByteRingBuffer :: RingBuffer(4, u8)
	buffer := ByteRingBuffer{}

	expectf(t, length(&buffer) == 0, "Starts off with empty buffer: Actual %v", length(&buffer))

	append(&buffer, 10)
	expect(t, length(&buffer) == 1, "It increases the length of the buffer")

	v, found := pop(&buffer)
	expect(t, found, "It found the option")
	expectf(t, v == 10, "Expected %v, found %v", 10, v)

	v, found = pop(&buffer)
	expect(t, !found, "It founds nothing")
	expectf(t, v == 0, "Expected %v, found %v", 0, v)
}

@(test)
test_ring_buffer_full :: proc(t: ^testing.T) {
	using testing

	ByteRingBuffer :: RingBuffer(4, u8)
	buffer := ByteRingBuffer{}

	expect(t, length(&buffer) == 0, "Starts off with empty buffer")


	success := append(&buffer, 5)
	expect(t, success, "Successfully adds")
	expectf(t, length(&buffer) == 1, "Increases the buffer")
	success = append(&buffer, 10)
	expect(t, success, "Successfully adds")
	expectf(t, length(&buffer) == 2, "Increases the buffer")
	success = append(&buffer, 15)
	expect(t, success, "Successfully adds")
	expectf(t, length(&buffer) == 3, "Increases the buffer")
	success = append(&buffer, 20)
	expectf(t, length(&buffer) == 4, "Fills up: length %v", buffer)

	success = append(&buffer, 25)
	expect(t, !success, "does not successfully add if full")
	expect(t, length(&buffer) == 4, "Stays at 4")
}

@(test)
test_ring_buffer_loop :: proc(t: ^testing.T) {
	using testing

	ByteRingBuffer :: RingBuffer(3, u8)
	buffer := ByteRingBuffer{}

	append(&buffer, 1)
	append(&buffer, 2)
	append(&buffer, 3)

	v, exists := pop(&buffer)
	expect(t, exists, "Value Exists")
	expect(t, v == 1, "returns the first value")
	v, exists = pop(&buffer)
	expect(t, exists, "Value Exists")
	expect(t, v == 2, "returns the first value")
	v, exists = pop(&buffer)
	expect(t, exists, "Value Exists")
	expect(t, v == 3, "returns the first value")

	append(&buffer, 4)
	expect(t, length(&buffer) == 1, "The buffer length is 1 after looping")
	append(&buffer, 5)
	expect(t, length(&buffer) == 2, "The buffer length is 1 after looping")

	success := append(&buffer, 6)
	expect(t, success, "stays healthy after looping")
	success = append(&buffer, 7)
	expect(t, !success, "Only handles 3 elements")

	v, exists = pop(&buffer)
	expectf(t, v == 4, "Expected: %v found: %v", 4, v)
	v, exists = pop(&buffer)
	expectf(t, v == 5, "Expected: %v found: %v", 5, v)
	v, exists = pop(&buffer)
	expectf(t, v == 6, "Expected: %v found: %v", 6, v)
}

@(test)
test_can_i_iter_ring_buffer :: proc(t: ^testing.T) {
	using testing
	ByteRingBuffer :: RingBuffer(3, u8)
	buffer := ByteRingBuffer{}

	append(&buffer, 1)
	append(&buffer, 2)
	append(&buffer, 3)

	i: u8 = 1
	for v in pop(&buffer) {
		assert(i <= 3, "In infinate loop")
		expectf(t, v == i, "Expected Value to be: %v, but found: %v", i, v)
		i += 1
	}

	expect(t, length(&buffer) == 0, "Ring Buffer should be empty")
}


@(test)
test_ring_buffer_iterator_simple :: proc(t: ^testing.T) {
	using testing
	ByteRingBuffer :: RingBuffer(3, u8)
	buffer := ByteRingBuffer{}

	append(&buffer, 1)
	append(&buffer, 2)
	append(&buffer, 3)

	iter := new_iter(&buffer)

	expect(t, iter.index == 0, "Starts off the same start index")

	v1, v1_has_more := iter_next(&iter)

	expect(t, v1 == 1)
	expect(t, v1_has_more == true)

	v2, v2_has_more := iter_next(&iter)
	expect(t, v2 == 2)
	expect(t, v2_has_more == true)

	v3, v3_has_more := iter_next(&iter)
	expect(t, v3 == 3)
	expect(t, v3_has_more == false)
}
