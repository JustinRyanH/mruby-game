package input

import "core:testing"
import math "core:math/linalg"

///////////////////////////////////////////
// Testing
///////////////////////////////////////////

@(test)
test_is_key_down :: proc(t: ^testing.T) {
	meta := FrameMeta{0, 1.0 / 60.0, 500, 700}

	last_frame := UserInput{meta, MouseInput{}, {}}
	current_frame := UserInput{meta, MouseInput{}, {.RIGHT}}

	input := FrameInput{current_frame, last_frame}


	testing.expect(t, is_pressed(input, KeyboardKey.RIGHT), "Right Arrow should be down")
	testing.expect(t, !is_pressed(input, KeyboardKey.LEFT), "Left Arrow should not be down")
	testing.expect(t, !is_pressed(input, .SPACE), "Space should not be down")
}

@(test)
test_is_mouse_button_ressed :: proc(t: ^testing.T) {
	meta := FrameMeta{0, 1.0 / 60.0, 500, 700}

	mouse_c := MouseInput{math.Vector2f32{}, {.LEFT}}
	mouse_p := MouseInput{math.Vector2f32{}, {}}

	last_frame := UserInput{meta, mouse_p, {}}
	current_frame := UserInput{meta, mouse_c, {}}
	input := FrameInput{current_frame, last_frame}

	testing.expect(t, is_pressed(input, MouseButton.LEFT), "Left mouse button is pressed")
	testing.expect(t, !is_pressed(input, MouseButton.RIGHT), "Right mouse button is not pressed")
}

@(test)
test_was_mouse_button_pressed :: proc(t: ^testing.T) {
	meta := FrameMeta{0, 1.0 / 60.0, 500, 700}
	mouse_c := MouseInput{math.Vector2f32{}, {}}
	mouse_p := MouseInput{math.Vector2f32{}, {.LEFT}}

	last_frame := UserInput{meta, mouse_p, {}}
	current_frame := UserInput{meta, mouse_c, {}}
	input := FrameInput{current_frame, last_frame}

	testing.expect(t, was_just_released(input, MouseButton.LEFT), "Left mouse button was pressed")
	testing.expect(
		t,
		!was_just_released(input, MouseButton.RIGHT),
		"Right mouse button was not pressed",
	)
}

@(test)
test_mouse_position :: proc(t: ^testing.T) {
	meta := FrameMeta{0, 1.0 / 60.0, 500, 700}
	mouse_c := MouseInput{math.Vector2f32{10, 10}, {}}
	mouse_p := MouseInput{math.Vector2f32{20, 20}, {}}

	last_frame := UserInput{meta, mouse_p, {}}
	current_frame := UserInput{meta, mouse_c, {}}
	input := FrameInput{current_frame, last_frame}

	testing.expect(
		t,
		mouse_position(input) == math.Vector2f32{10, 10},
		"Mouse position is correct",
	)
	testing.expect(t, mouse_delta(input) == math.Vector2f32{-10, -10}, "Mouse delta is correct")
}
