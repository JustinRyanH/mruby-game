package main

import "core:sort"

RectPackContext :: struct {
	width:       i32,
	height:      i32,
	alignment:   i32,
	has_init:    bool,
	heuristic:   RectPackHeuristic,
	active_head: ^RectPackNode,
	free_head:   ^RectPackNode,
	extra:       [2]RectPackNode,
}

STBRP__MAXVAL :: 0x7fffffff

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

RectPackHeuristic :: enum i32 {
	Skyline_default = 0,
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
// TODO: return boolean
rp_pack_rects :: proc(ctx: ^RectPackContext, rects: [^]RectPackRect, num_rects: i32) -> i32 {
	i: i32
	all_rects_packed: i32 = 1

	for i = 0; i < num_rects; i += 1 {
		rects[i].was_packed = i
	}

	sort.quick_sort_proc(rects[0:num_rects], rect_height_compare)

	// for i = 0; i < num_rects; i += 1 {
	// 	if rects[i].w == 0 || rects[i].h == 0 {
	// 		rects[i].x = 0
	// 		rects[i].y = 0
	// 	} else {
	// 	}
	//
	// }

	sort.quick_sort_proc(rects[0:num_rects], rect_original_order)

	for i = 0; i < num_rects; i += 1 {
		rects[i].was_packed = i32(!(rects[i].x == STBRP__MAXVAL && rects[i].y == STBRP__MAXVAL))

		if rects[i].was_packed == 0 {
			all_rects_packed = 0
		}
	}

	return all_rects_packed
}

find_result :: struct {
	x, y:      i32,
	prev_link: ^^RectPackNode,
}


rect_height_compare :: proc(a, b: RectPackRect) -> int {
	if a.h > b.h {
		return -1
	}
	if a.h < b.h {
		return 1
	}
	if a.w > b.w {
		return -1
	}
	if a.w < b.w {
		return 1
	}
	return 0
}

rect_original_order :: proc(a, b: RectPackRect) -> int {
	if (a.was_packed < b.was_packed) {
		return -1
	}
	if (a.was_packed > b.was_packed) {
		return 1
	}
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
rp_init_target :: proc(ctx: ^RectPackContext, width, height: i32, nodes: []RectPackNode) {
	i: int

	for i = 0; i < len(nodes) - 1; i += 1 {
		nodes[i].next = &nodes[i + 1]
	}
	nodes[i].next = nil
	ctx.has_init = true
	ctx.heuristic = .Skyline_default
	ctx.free_head = &nodes[0]
	ctx.active_head = &ctx.extra[0]
	ctx.width = width
	ctx.height = height
	// TODO: allow oom
	ctx.alignment = 1

	ctx.extra[0].x = 0
	ctx.extra[0].y = 0
	ctx.extra[0].next = &ctx.extra[1]
	ctx.extra[1].x = width
	ctx.extra[1].y = 1 << 30
	ctx.extra[1].next = nil
}

// Optionally call this function after init but before doing any packing to
// change the handling of the out-of-temp-memory scenario, described above.
// If you call init again, this will be reset to the default (false).
rp_setup_allow_out_of_mem :: proc(ctx: ^RectPackContext, allow_oom: bool) {}

// Optionally select which packing heuristic the library should use. Different
// heuristics will produce better/worse results for different data sets.
// If you call init again, this will be reset to the default.
rp_setup_heuristic :: proc(ctx: ^RectPackContext, heuristic: RectPackHeuristic) {}
