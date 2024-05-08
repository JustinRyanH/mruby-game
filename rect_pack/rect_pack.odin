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
}
