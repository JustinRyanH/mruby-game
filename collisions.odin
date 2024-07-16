package main

import dp "./data_pool"

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

			_, collide := shape_are_rects_colliding_obb(rect_a, rect_b)
			if !collide {
				continue
			}
			game_add_collision(game, handle_a, handle_b)
		}
	}
}
