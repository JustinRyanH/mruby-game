package rect_pack

// Copyright (c) 2017 Sean Barrett, 2024 Justin Hurstwright
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


Coord :: distinct int
_MAXVAL :: max(Coord)
INIT_SKYLINE :: 1

Rect :: struct {
	// reserved for your use:
	id:         int,

	// input:
	w, h:       Coord,

	// output:
	x, y:       Coord,
	was_packed: bool, // non-zero if valid packing
}

Heuristic :: enum u8 {
	Skyline_default = 0,
	Skyline_BL_sortHeight = Skyline_default,
	Skyline_BF_sortHeight,
}

//////////////////////////////////////////////////////////////////////////////
//
// the details of the following structures don't matter to you, but they must
// be visible so you can handle the memory allocations for them

PackError :: enum {
	None,
	UnconfiguredContext,
}

Node :: struct {
	x, y: Coord,
	next: ^Node,
}

Context :: struct {
	width, height: int,
	align:         int,
	init_mode:     i32,
	heuristic:     Heuristic,
	num_nodes:     int,
	active_head:   ^Node,
	free_head:     ^Node,
	extra:         [2]Node, // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
}

@(private)
FindResult :: struct {
	x, y: Coord,
	prev: ^Node,
}


setup_heuristic :: proc "contextless" (ctx: ^Context, h: Heuristic) -> PackError {
	if ctx.init_mode != INIT_SKYLINE {
		return .UnconfiguredContext
	}
	ctx.heuristic = h
	return .None
}

setup_allow_out_of_mem :: proc "contextless" (ctx: ^Context, allow_out_of_mem: bool) {
	if allow_out_of_mem {
		// if it's ok to run out of memory, then don't bother aligning them;
		// this gives better packing, but may fail due to OOM (even though
		// the rectangles easily fit). @TODO a smarter approach would be to only
		// quantize once we've hit OOM, then we could get rid of this parameter.
		ctx.align = 1
	}
	// if it's not ok to run out of memory, then quantize the widths
	// so that num_nodes is always enough nodes.
	//
	// I.e. num_nodes * align >= width
	//                  align >= width / num_nodes
	//                  align = ceil(width/num_nodes)
	ctx.align = ctx.width + (ctx.width + ctx.num_nodes - 1) / ctx.num_nodes
}

init_targets :: proc "contextless" (ctx: ^Context, width, height: int, nodes: []Node) {
	i: int
	for i = 0; i < len(nodes); i += 1 {
		nodes[i].next = &nodes[i + 1]
	}
	nodes[i].next = nil

	ctx.init_mode = INIT_SKYLINE
	ctx.heuristic = .Skyline_default
	ctx.free_head = &nodes[0]
	ctx.active_head = &ctx.extra[0]
	ctx.width = width
	ctx.height = height
	ctx.num_nodes = len(nodes)
	setup_allow_out_of_mem(ctx, false)

	ctx.extra[0].x = 0
	ctx.extra[0].y = 0
	ctx.extra[0].next = &ctx.extra[1]
	ctx.extra[1].x = cast(Coord)width
	ctx.extra[1].y = 1 << 30
	ctx.extra[1].next = nil
}

// find minimum y position if it starts at x1
skyline_find_min_y :: proc(
	ctx: ^Context,
	nodes: []Node,
	x0: Coord,
	width: int,
) -> (
	min_y, waste_area: int,
) {
	idx := 0
	x1 := x0 + cast(Coord)width
	for nodes[idx].x < x0 {
		idx += 1
	}

	min_y = 0
	waste_area = 0
	visited_width := 0

	for nodes[idx].x < x1 {
		node := &nodes[idx]
		next := nodes[idx + 1]
		if node.y > cast(Coord)min_y {
			// raise min_y higher.
			// we've accounted for all waste up to min_y,
			// but we'll now add more waste for everything we've visted
			waste_area += visited_width * (cast(int)node.y - min_y)
			min_y = cast(int)node.y
			if node.x < x0 {
				visited_width += cast(int)(next.x - x0)
			} else {
				visited_width += cast(int)(next.x - node.x)
			}
		} else {
			// add waste area
			under_width := cast(int)(next.x - node.x)
			if (under_width + visited_width > width) {
				under_width = width - visited_width
			}
			waste_area += under_width * (min_y - cast(int)node.y)
			visited_width += under_width
		}
		idx += 1
	}

	return
}
