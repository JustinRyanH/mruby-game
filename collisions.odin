package main

import dp "./data_pool"

ColliderRegionPos :: struct {
	x, y: u32,
}

RegionColliders :: struct {
	colliders: []Collider,
	count:     u32,
}

CollisionEvent :: struct {
	other:  ColliderHandle,
	normal: Vector2,
	depth:  f32,
}
CollisionTargets :: [dynamic]CollisionEvent
Collisions :: map[ColliderHandle]CollisionTargets

game_add_collision :: proc(game: ^Game, a, b: ColliderHandle, contact: ContactEvent) {
	if !(a in game.collision_evts_t) {
		game.collision_evts_t[a] = make(CollisionTargets, 0, 16, context.temp_allocator)
	}
	if !(b in game.collision_evts_t) {
		game.collision_evts_t[b] = make(CollisionTargets, 0, 16, context.temp_allocator)
	}

	when !ODIN_DISABLE_ASSERT {
		for v in game.collision_evts_t[a] {
			assert(v.other != a, "Item should not collide with itself")
			assert(v.other != b, "An item should not collide with itself twice")
		}
		for v in game.collision_evts_t[b] {
			assert(v.other != b, "Item should not collide with itself")
			assert(v.other != a, "An item should not collide with itself twice")
		}
	}

	append(&game.collision_evts_t[a], CollisionEvent{b, contact.normal, contact.depth})
	append(&game.collision_evts_t[b], CollisionEvent{a, -contact.normal, -contact.depth})
}


game_check_collisions :: proc(game: ^Game) {
	iter_a := dp.new_iter(&game.colliders)
	for entity_a, handle_a in dp.iter_next(&iter_a) {
		iter_b := dp.new_iter_start_at(&game.colliders, handle_a)
		for entity_b, handle_b in dp.iter_next(&iter_b) {
			if handle_a == handle_b {
				continue
			}
			rect_a := Rectangle{entity_a.pos, entity_a.size}
			rect_b := Rectangle{entity_b.pos, entity_b.size}

			contact, collide := shape_are_rects_colliding_obb(rect_a, rect_b)
			if !collide {
				continue
			}
			game_add_collision(game, handle_a, handle_b, contact)
		}
	}
}
