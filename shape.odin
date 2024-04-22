package main

import math "core:math/linalg"

import rl "vendor:raylib"

Vector2 :: rl.Vector2

Rectangle :: struct {
	pos:  Vector2,
	size: Vector2,
}

CollisionEvent :: struct {
	a, b: EntityHandle,
}

// Check collision between two rectangles using AABB, assumes there is no rotation
shape_are_rects_colliding_aabb :: proc(rec_a, rec_b: Rectangle) -> bool {
	rect_a_min, rect_a_extends := shape_get_rect_extends(rec_a)
	rect_b_min, rect_b_extends := shape_get_rect_extends(rec_b)

	overlap_horizontal := (rect_a_min.x < rect_b_extends.x) && (rect_a_extends.x > rect_b_min.x)
	overlap_vertical := (rect_a_min.y < rect_b_extends.y) && (rect_a_extends.y > rect_b_min.y)

	return overlap_horizontal && overlap_vertical
}

// Get the min and max vectors of a rectangles
shape_get_rect_extends :: proc(rect: Rectangle) -> (math.Vector2f32, math.Vector2f32) {
	rect_min := rect.pos - (rect.size * 0.5)
	rect_max := rect.pos + (rect.size * 0.5)
	return rect_min, rect_max
}
