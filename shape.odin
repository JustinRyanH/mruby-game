package main

import math "core:math/linalg"

import rl "vendor:raylib"

Rectangle :: struct {
	pos:  Vector2,
	size: Vector2,
}

ContactEvent :: struct {
	normal: Vector2,
	depth:  f32,
}

// Check collision between two rectangles using AABB, assumes there is no rotation
shape_are_rects_colliding_aabb :: proc(rec_a, rec_b: Rectangle) -> bool {
	rect_a_min, rect_a_extends := shape_get_rect_extends(rec_a)
	rect_b_min, rect_b_extends := shape_get_rect_extends(rec_b)

	overlap_horizontal := (rect_a_min.x < rect_b_extends.x) && (rect_a_extends.x > rect_b_min.x)
	overlap_vertical := (rect_a_min.y < rect_b_extends.y) && (rect_a_extends.y > rect_b_min.y)

	return overlap_horizontal && overlap_vertical
}

// Check collision between two rectangles using AABB, assumes there is no rotation
shape_are_rects_colliding_obb :: proc(
	rect_a, rect_b: Rectangle,
) -> (
	event: ContactEvent,
	is_colliding: bool,
) {
	event.depth = max(f32)
	rect_a_vertices := shape_get_rect_vertices(rect_a)
	rect_b_vertices := shape_get_rect_vertices(rect_b)

	for _, i in rect_a_vertices {
		a := rect_a_vertices[i]
		b := rect_a_vertices[(i + 1) % len(rect_a_vertices)]

		edge := b - a
		axis := shape_vector_normalize_perp(edge)

		min_a, max_a := shape_project_vertices_to_axis(rect_a_vertices[:], axis)
		min_b, max_b := shape_project_vertices_to_axis(rect_b_vertices[:], axis)

		if min_a >= max_b || min_b >= max_a {
			return ContactEvent{}, false
		}

		depth := math.min(max_b - min_a, max_a - min_b)
		if (depth < event.depth) {
			event.depth = depth
			event.normal = axis
		}
	}

	for _, i in rect_b_vertices {
		a := rect_b_vertices[i]
		b := rect_b_vertices[(i + 1) % len(rect_b_vertices)]

		edge := b - a
		axis := shape_vector_normalize_perp(edge)

		min_a, max_a := shape_project_vertices_to_axis(rect_a_vertices[:], axis)
		min_b, max_b := shape_project_vertices_to_axis(rect_b_vertices[:], axis)

		if min_a >= max_b || min_b >= max_a {
			return ContactEvent{}, false
		}

		depth := math.min(max_b - min_a, max_a - min_b)
		if (depth < event.depth) {
			event.depth = depth
			event.normal = axis
		}
	}

	is_colliding = true

	dir := rect_a.pos - rect_b.pos
	if (math.dot(dir, event.normal) < 0) {
		event.normal *= -1
	}

	return
}


// Get the min and max vectors of a rectangles
shape_get_rect_extends :: proc(rect: Rectangle) -> (math.Vector2f32, math.Vector2f32) {
	rect_min := rect.pos - (rect.size * 0.5)
	rect_max := rect.pos + (rect.size * 0.5)
	return rect_min, rect_max
}


// Get the vertices around a rectangle, clockwise
@(private = "file")
shape_get_rect_vertices :: proc(rect: Rectangle) -> (vertices: [4]Vector2) {
	len := math.length(rect.size) / 2
	nm_v := math.normalize(rect.size)
	normalized_points := [4]Vector2 {
		-nm_v,
		Vector2{nm_v.x, -nm_v.y},
		Vector2{nm_v.x, nm_v.y},
		Vector2{-nm_v.x, nm_v.y},
	}

	rad: f32 = shape_get_rotation(rect)
	for vertex, i in normalized_points {
		rotated_point := vertex
		rotated_point.x = vertex.x * math.cos(rad) - vertex.y * math.sin(rad)
		rotated_point.y = vertex.x * math.sin(rad) + vertex.y * math.cos(rad)
		vertices[i] = rect.pos + rotated_point * len
	}


	return vertices
}

@(private = "file")
shape_get_rotation :: #force_inline proc(rect: Rectangle) -> f32 {
	return 0
}

// Rotates the Vector 90 counter clockwise, normalized
@(private = "file")
shape_vector_normalize_perp :: proc(vec: Vector2) -> Vector2 {
	v := math.normalize(vec)
	l := math.length(vec)
	return Vector2{-v.y, v.x}
}

@(private = "file")
shape_project_vertices_to_axis :: proc(vertices: []Vector2, axis: Vector2) -> (min_t, max_t: f32) {
	min_t = max(f32)
	max_t = min(f32)

	for vertex in vertices {
		dp := math.dot(vertex, axis)
		max_t = math.max(dp, max_t)
		min_t = math.min(dp, min_t)
	}


	return
}
