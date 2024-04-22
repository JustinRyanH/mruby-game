package data_pool

import "core:testing"

Handle :: distinct i64
HandleStruct :: struct {
	idx: u32,
	gen: u32,
}
NilHandleStruct :: HandleStruct{}

DataContainer :: struct($T: typeid) {
	id:   HandleStruct,
	data: T,
}

DataPool :: struct($N: u32, $T: typeid, $H: typeid/Handle) {
	items_len:        u32,
	unused_items_len: u32,
	items:            [N]DataContainer(T),
	unused_items:     [N]HandleStruct,
}

DataPoolIterator :: struct($N: u32, $T: typeid, $H: typeid/Handle) {
	dp:    ^DataPool(N, T, H),
	index: int,
}


add :: proc "contextless" (dp: ^DataPool($N, $T, $H), v: T) -> (H, bool) {
	if (dp.items_len == N && dp.unused_items_len == 0) {
		return 0, false
	}
	if (dp.unused_items_len > 0) {
		handle := dp.unused_items[dp.unused_items_len - 1]
		if handle.gen == max(u32) {
			handle.gen = 0
		}
		handle.gen += 1
		dp.items[handle.idx] = DataContainer(T){handle, v}
		dp.unused_items_len -= 1
		return transmute(H)handle, true
	}

	handle := HandleStruct{dp.items_len, 1}
	dp.items[dp.items_len] = DataContainer(T){handle, v}
	dp.items_len += 1

	return transmute(H)handle, true
}

get :: proc "contextless" (dp: ^DataPool($N, $T, $H), h: H) -> (data: T, found: bool) {
	hs := transmute(HandleStruct)h

	db := dp.items[hs.idx]
	if (db.id == hs) {
		return db.data, true
	}
	return
}

valid :: proc "contextless" (dp: ^DataPool($N, $T, $H), h: H) -> bool {
	hs := transmute(HandleStruct)h

	db := dp.items[hs.idx]
	if (db.id == hs) {
		return true
	}
	return false
}

add_empty :: proc "contextless" (dp: ^DataPool($N, $T, $H)) -> (^T, H, bool) {
	h, success := add(dp, T{})
	if !success {
		return nil, 0, false
	}
	ptr := get_ptr(dp, h)
	if ptr == nil {
		return nil, 0, false
	}
	return ptr, h, true
}

get_ptr :: proc "contextless" (dp: ^DataPool($N, $T, $H), h: H) -> ^T {
	hs := transmute(HandleStruct)h

	db := dp.items[hs.idx]
	if (db.id == hs) {
		return &dp.items[hs.idx].data
	}
	return nil
}


remove :: proc "contextless" (dp: ^DataPool($N, $T, $H), h: H) -> bool {
	hs := transmute(HandleStruct)h

	db := dp.items[hs.idx]
	if (db.id == hs) {

		item := &dp.items[hs.idx]
		dp.unused_items[dp.unused_items_len] = item.id
		dp.unused_items_len += 1
		item.id = HandleStruct{}
		item.data = T{}

		return true
	}


	return false
}


length :: proc "contextless" (dp: ^DataPool($N, $T, $H)) -> int {
	return cast(int)(dp.items_len - dp.unused_items_len)
}

new_iter :: proc "contextless" (dp: ^DataPool($N, $T, $H)) -> DataPoolIterator(N, T, H) {
	return DataPoolIterator(N, T, H){dp = dp}
}

// Creates a new iterator that starts at a handle
new_iter_start_at :: proc "contextless" (
	dp: ^DataPool($N, $T, $H),
	handle: H,
) -> DataPoolIterator(N, T, H) {
	start_index := get_handle_index(H, handle)
	return DataPoolIterator(N, T, H){dp = dp, index = start_index}
}


// Soft resets the Data Pool.
// This is used when there might be handles after clear
// is performed
reset :: proc "contextless" (db: ^DataPool($N, $T, $H)) {
	for i := len(db.items) - 1; i >= 0; i -= 1 {
		item_pos := N - 1 - cast(u32)i
		db.unused_items[i] = db.items[item_pos].id
		db.unused_items[i].idx = item_pos
		db.items[i].id = NilHandleStruct
	}
	db.items_len = N
	db.unused_items_len = N
}

// "Hard" resets the DataPool
// Use this when there are no dangling handles 
// that could cause data issues
hard_reset :: proc "contextless" (db: ^DataPool($N, $T, $H)) {
	db.unused_items_len = 0
	db.items_len = 0
}

iter_next :: proc "contextless" (
	it: ^DataPoolIterator($N, $T, $H),
) -> (
	data: T,
	h: H,
	cond: bool,
) {
	cond = it.index < cast(int)it.dp.items_len

	for ; cond; cond = it.index < cast(int)it.dp.items_len {
		dc := it.dp.items[it.index]
		if dc.id == NilHandleStruct {
			it.index += 1
			continue
		}
		data = dc.data
		h = transmute(H)dc.id
		it.index += 1
		break
	}

	return
}

iter_next_ptr :: proc "contextless" (
	it: ^DataPoolIterator($N, $T, $H),
) -> (
	data: ^T,
	h: H,
	cond: bool,
) {
	cond = it.index < cast(int)it.dp.items_len

	for ; cond; cond = it.index < cast(int)it.dp.items_len {
		dc := it.dp.items[it.index]
		if dc.id == NilHandleStruct {
			it.index += 1
			continue
		}
		data = &it.dp.items[it.index].data
		h = transmute(H)dc.id
		it.index += 1
		break
	}

	return
}

@(private = "file")
get_handle_index :: proc "contextless" ($H: typeid, handle: H) -> int {
	hs := transmute(HandleStruct)handle
	return cast(int)hs.idx
}

/////////////////////////////
// Tests
/////////////////////////////

@(test)
test_data_pool_add_simple :: proc(t: ^testing.T) {
	assert(size_of(HandleStruct) == size_of(Handle))
	TestStruct :: struct {
		v: u8,
	}

	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	for i := 0; i < 4; i += 1 {
		handle, success := add(&byte_dp, TestStruct{cast(u8)i + 5})
		testing.expectf(t, success, "Data should have been added at index %d", i)
		testing.expectf(t, handle != 0, "Data should have returned non-zero handle at index %d", i)
	}

	handle, success := add(&byte_dp, TestStruct{244})
	testing.expect(t, !success, "Success returns false if it is full")

}

@(test)
test_data_pool_add_reuse :: proc(t: ^testing.T) {

	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	handle_a, success_a := add(&byte_dp, TestStruct{33})
	testing.expect(t, success_a, "data should have been added")

	was_removed := remove(&byte_dp, handle_a)
	testing.expect(t, was_removed, "data should have been removed")

	handle_b, success_b := add(&byte_dp, TestStruct{33})
	testing.expect(t, success_b, "data cannot be removed twice")

	handle_struct_b := transmute(HandleStruct)handle_b
	handle_struct_a := transmute(HandleStruct)handle_a

	testing.expect(
		t,
		handle_struct_a.idx == handle_struct_b.idx,
		"it re-uses the previously used spots",
	)
	testing.expect(
		t,
		handle_struct_b.gen > handle_struct_a.gen,
		"it iterates the handle generation",
	)
}


@(test)
test_data_pool_get :: proc(t: ^testing.T) {
	assert(size_of(HandleStruct) == size_of(Handle))
	TestStruct :: struct {
		v: u8,
	}

	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	handle, success := add(&byte_dp, TestStruct{33})
	testing.expect(t, success, "Data should have been added")

	data, found := get(&byte_dp, handle)

	testing.expect(t, found, "Data should have been found")
	testing.expectf(t, data.v == 33, "Data should have been 33, but was %d", data)
}

@(test)
test_data_pool_get_ptr :: proc(t: ^testing.T) {
	assert(size_of(HandleStruct) == size_of(Handle))
	TestStruct :: struct {
		v: u8,
	}

	ByteDataPool :: DataPool(4, u8, Handle)
	byte_dp := ByteDataPool{}

	handle, success := add(&byte_dp, 33)
	testing.expect(t, success, "data should have been added")

	{
		data_ptr := get_ptr(&byte_dp, handle)
		data_ptr^ = 50
	}

	data, found := get(&byte_dp, handle)
	testing.expect(t, found, "Data should have been found")
	testing.expect(t, data == 50, "Data should have been adjusted in memory")
}

@(test)
test_data_pool_remove :: proc(t: ^testing.T) {
	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	handle_a, success_a := add(&byte_dp, TestStruct{33})
	testing.expect(t, success_a, "data should have been added")
	handle_b, success_b := add(&byte_dp, TestStruct{44})
	testing.expect(t, success_a, "data should have been added")

	was_removed := remove(&byte_dp, handle_a)
	testing.expect(t, was_removed, "data should have been removed")
	was_removed = remove(&byte_dp, handle_a)
	testing.expect(t, !was_removed, "data cannot be removed twice")
}

@(test)
test_data_pool_iterator :: proc(t: ^testing.T) {
	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	handle_a, success_a := add(&byte_dp, TestStruct{33})
	handle_b, success_b := add(&byte_dp, TestStruct{77})
	handle_c, success_c := add(&byte_dp, TestStruct{100})
	handle_d, success_d := add(&byte_dp, TestStruct{240})
	successes := []bool{success_a, success_b, success_c, success_d}
	for success in successes {
		testing.expect(t, success, "data should have been added")
	}

	removed := remove(&byte_dp, handle_b)
	testing.expect(t, removed, "data should have been removed")

	iter := new_iter(&byte_dp)


	data, handle, should_continue := iter_next(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 33, "The first value should be 33")
	testing.expect(t, handle == handle_a, "The first handle should be handle_a")

	data, handle, should_continue = iter_next(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 100, "The first value should be 100")
	testing.expect(t, handle == handle_c, "The first handle should be handle_a")

	data, handle, should_continue = iter_next(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 240, "The first value should be 100")
	testing.expect(t, handle == handle_d, "The first handle should be handle_a")

	data, handle, should_continue = iter_next(&iter)
	testing.expect(t, !should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 0, "The first value should be 100")
	testing.expect(t, handle == 0, "The first handle should be handle_a")
}

@(test)
test_data_pool_iterator_ptr :: proc(t: ^testing.T) {
	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	handle_a, success_a := add(&byte_dp, TestStruct{33})
	handle_b, success_b := add(&byte_dp, TestStruct{77})
	handle_c, success_c := add(&byte_dp, TestStruct{100})
	handle_d, success_d := add(&byte_dp, TestStruct{240})
	successes := []bool{success_a, success_b, success_c, success_d}
	for success in successes {
		testing.expect(t, success, "data should have been added")
	}

	removed := remove(&byte_dp, handle_b)
	testing.expect(t, removed, "data should have been removed")

	iter := new_iter(&byte_dp)


	data, handle, should_continue := iter_next_ptr(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 33, "The first value should be 33")
	testing.expect(t, handle == handle_a, "The first handle should be handle_a")

	data, handle, should_continue = iter_next_ptr(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 100, "The first value should be 100")
	testing.expect(t, handle == handle_c, "The first handle should be handle_a")

	data, handle, should_continue = iter_next_ptr(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 240, "The first value should be 100")
	testing.expect(t, handle == handle_d, "The first handle should be handle_a")

	data, handle, should_continue = iter_next_ptr(&iter)
	testing.expect(t, !should_continue, "There should be more iterations left")
	testing.expect(t, data == nil, "The first value should be 100")
	testing.expect(t, handle == 0, "The first handle should be handle_a")
}

@(test)
test_data_pool_reset :: proc(t: ^testing.T) {
	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(1, TestStruct, Handle)
	byte_dp := ByteDataPool{}

	handle_a, success := add(&byte_dp, TestStruct{30})
	testing.expect(t, success, "data should have been added")

	reset(&byte_dp)

	v, found := get(&byte_dp, handle_a)
	testing.expect(t, !found, "data should not have been found")
	testing.expect(t, v == TestStruct{}, "data should be empty")


	handle_b, success_b := add(&byte_dp, TestStruct{77})
	testing.expect(t, success_b, "data should have been added")

	v, found = get(&byte_dp, handle_b)
	testing.expect(t, found, "data should have been found")
	testing.expect(t, v == TestStruct{77}, "should be the second object")
}

@(test)
test_data_pool_iterator_reset :: proc(t: ^testing.T) {
	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(4, TestStruct, Handle)
	byte_dp := ByteDataPool{}
	reset(&byte_dp)

	handle_a, success_a := add(&byte_dp, TestStruct{33})
	handle_b, success_b := add(&byte_dp, TestStruct{77})
	handle_c, success_c := add(&byte_dp, TestStruct{100})
	handle_d, success_d := add(&byte_dp, TestStruct{240})
	successes := []bool{success_a, success_b, success_c, success_d}
	for success in successes {
		testing.expect(t, success, "data should have been added")
	}

	removed := remove(&byte_dp, handle_b)
	testing.expect(t, removed, "data should have been removed")

	iter := new_iter(&byte_dp)


	data, handle, should_continue := iter_next(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 33, "The first value should be 33")
	testing.expect(t, handle == handle_a, "The first handle should be handle_a")

	data, handle, should_continue = iter_next(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 100, "The first value should be 100")
	testing.expect(t, handle == handle_c, "The first handle should be handle_a")

	data, handle, should_continue = iter_next(&iter)
	testing.expect(t, should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 240, "The first value should be 100")
	testing.expect(t, handle == handle_d, "The first handle should be handle_a")

	data, handle, should_continue = iter_next(&iter)
	testing.expect(t, !should_continue, "There should be more iterations left")
	testing.expect(t, data.v == 0, "The first value should be 100")
	testing.expect(t, handle == 0, "The first handle should be handle_a")
}

@(test)
test_data_pool_add_empty :: proc(t: ^testing.T) {
	TestStructA :: struct {
		v: u8,
	}
	TestStructB :: struct {
		v: i8,
	}
	TestUnion :: union {
		TestStructA,
		TestStructB,
	}
	ByteDataPool :: DataPool(4, TestUnion, Handle)
	byte_dp := ByteDataPool{}

	empty_ptr, handle, success := add_empty(&byte_dp)
	testing.expect(t, success, "It should have successfully added")
	testing.expect(t, handle != 0, "It have a non-zero handle")
	testing.expectf(
		t,
		empty_ptr^ == nil,
		"It returns a nil version of the union, got %v",
		empty_ptr,
	)

	empty_ptr^ = TestStructB{-8}

	data, found := get(&byte_dp, handle)
	testing.expect(t, found, "Handle should have data in pool")
	testing.expectf(t, data == TestStructB{-8}, "Data should Exists, found %v", data)
}

@(test)
test_data_pool_len :: proc(t: ^testing.T) {
	TestStruct :: struct {
		v: u8,
	}
	ByteDataPool :: DataPool(4, TestStruct, Handle)
	data_pool_example := ByteDataPool{}

	add(&data_pool_example, TestStruct{33})
	handle, _ := add(&data_pool_example, TestStruct{31})
	remove(&data_pool_example, handle)
	add(&data_pool_example, TestStruct{40})


	testing.expect(t, length(&data_pool_example) == 2, "The length should be 2")
}
