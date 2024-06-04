package main

RectPackContext :: struct {
	width:       i32,
	height:      i32,
	alignment:   i32,
	has_init:    bool,
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

RectPackHeuristic :: enum {
	Skyline_BL_SortHeight = 0,
	Skyline_BF_SortHeight,
}

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

// Initialize a rectangle packer to:
//    pack a rectangle that is 'width' by 'height' in dimensions
//    using temporary storage provided by the array 'nodes', which is 'num_nodes' long
//
// You must call this function every time you start packing into a new target.
//
// There is no "shutdown" function. The 'nodes' memory must stay valid for
// the following stbrp_pack_rects() call (or calls), but can be freed after
// the call (or calls) finish.
//
// Note: to guarantee best results, either:
//       1. make sure 'num_nodes' >= 'width'
//   or  2. call stbrp_allow_out_of_mem() defined below with 'allow_out_of_mem = 1'
//
// If you don't do either of the above things, widths will be quantized to multiples
// of small integers to guarantee the algorithm doesn't run out of temporary storage.
//
// If you do #2, then the non-quantized algorithm will be used, but the algorithm
// may run out of temporary storage and be unable to pack some rectangles.
rp_init_target :: proc(
	ctx: ^RectPackContext,
	width, height: int,
	nodes: [^]RectPackContext,
	num_nodes: i32,
) {}

// Optionally call this function after init but before doing any packing to
// change the handling of the out-of-temp-memory scenario, described above.
// If you call init again, this will be reset to the default (false).
rp_setup_allow_out_of_mem :: proc(ctx: ^RectPackContext, allow_oom: bool) {}

// Optionally select which packing heuristic the library should use. Different
// heuristics will produce better/worse results for different data sets.
// If you call init again, this will be reset to the default.
rp_setup_heuristic :: proc(ctx: ^RectPackContext, heuristic: RectPackHeuristic) {}
