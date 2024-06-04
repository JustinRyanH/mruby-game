package main

RectPackContext :: struct {
	width:       i32,
	height:      i32,
	alignment:   i32,
	init_mode:   i32,
	heuristic:   i32,
	num_nodes:   i32,
	active_head: ^RectPackNode,
	free_head:   ^RectPackNode,
	extra:       [2]RectPackNode,
}

RectPackNode :: struct {
	x, y: RectPackCoord,
	next: ^RectPackNode,
}
RectPackRect :: struct {
	id:         i32,
	w, h:       RectPackCoord,
	x, y:       RectPackCoord,
	was_packed: i32,
}

RectPackCoord :: i32

// Assign packed locations to rectangles. The rectangles are of type
// 'stbrp_rect' defined below, stored in the array 'rects', and there
// are 'num_rects' many of them.
//
// Rectangles which are successfully packed have the 'was_packed' flag
// set to a non-zero value and 'x' and 'y' store the minimum location
// on each axis (i.e. bottom-left in cartesian coordinates, top-left
// if you imagine y increasing downwards). Rectangles which do not fit
// have the 'was_packed' flag set to 0.
//
// You should not try to access the 'rects' array from another thread
// while this function is running, as the function temporarily reorders
// the array while it executes.
//
// To pack into another rectangle, you need to call stbrp_init_target
// again. To continue packing into the same rectangle, you can call
// this function again. Calling this multiple times with multiple rect
// arrays will probably produce worse packing results than calling it
// a single time with the full rectangle array, but the option is
// available.
//
// The function returns 1 if all of the rectangles were successfully
// packed and 0 otherwise.
rp_pack_rects :: proc(ctx: ^RectPackContext, rects: [^]RectPackRect, num_rects: i32) -> i32 {
	return 0
}
