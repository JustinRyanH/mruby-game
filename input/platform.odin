package input

import math "core:math/linalg"

import rl "vendor:raylib"


RlToGameKeyMap :: struct {
	rl_key:   rl.KeyboardKey,
	game_key: KeyboardKey,
}

RlToGameMouseMap :: struct {
	rl_btn:   rl.MouseButton,
	game_btn: MouseButton,
}

keys_to_check :: [?]RlToGameKeyMap {
	{.COMMA, .COMMA},
	{.MINUS, .MINUS},
	{.PERIOD, .PERIOD},
	{.SLASH, .SLASH},
	{.ZERO, .ZERO},
	{.ONE, .ONE},
	{.TWO, .TWO},
	{.THREE, .THREE},
	{.FOUR, .FOUR},
	{.FIVE, .FIVE},
	{.SIX, .SIX},
	{.SEVEN, .SEVEN},
	{.EIGHT, .EIGHT},
	{.NINE, .NINE},
	{.SEMICOLON, .SEMICOLON},
	{.EQUAL, .EQUAL},
	{.A, .A},
	{.B, .B},
	{.C, .C},
	{.D, .D},
	{.E, .E},
	{.F, .F},
	{.G, .G},
	{.H, .H},
	{.I, .I},
	{.J, .J},
	{.K, .K},
	{.L, .L},
	{.M, .M},
	{.N, .N},
	{.O, .O},
	{.P, .P},
	{.Q, .Q},
	{.R, .R},
	{.S, .S},
	{.T, .T},
	{.U, .U},
	{.V, .V},
	{.W, .W},
	{.X, .X},
	{.Y, .Y},
	{.Z, .Z},
	{.LEFT_BRACKET, .LEFT_BRACKET},
	{.BACKSLASH, .BACKSLASH},
	{.RIGHT_BRACKET, .RIGHT_BRACKET},
	{.GRAVE, .GRAVE},
	{.SPACE, .SPACE},
	{.ESCAPE, .ESCAPE},
	{.ENTER, .ENTER},
	{.TAB, .TAB},
	{.BACKSPACE, .BACKSPACE},
	{.INSERT, .INSERT},
	{.DELETE, .DELETE},
	{.RIGHT, .RIGHT},
	{.LEFT, .LEFT},
	{.DOWN, .DOWN},
	{.UP, .UP},
	{.PAGE_UP, .PAGE_UP},
	{.PAGE_DOWN, .PAGE_DOWN},
	{.HOME, .HOME},
	{.END, .END},
	{.CAPS_LOCK, .CAPS_LOCK},
	{.SCROLL_LOCK, .SCROLL_LOCK},
	{.NUM_LOCK, .NUM_LOCK},
	{.PRINT_SCREEN, .PRINT_SCREEN},
	{.PAUSE, .PAUSE},
	{.F1, .F1},
	{.F2, .F2},
	{.F3, .F3},
	{.F4, .F4},
	{.F5, .F5},
	{.F6, .F6},
	{.F7, .F7},
	{.F8, .F8},
	{.F9, .F9},
	{.F10, .F10},
	{.F11, .F11},
	{.F12, .F12},
	{.LEFT_SHIFT, .LEFT_SHIFT},
	{.LEFT_CONTROL, .LEFT_CONTROL},
	{.LEFT_ALT, .LEFT_ALT},
	{.LEFT_SUPER, .LEFT_SUPER},
	{.RIGHT_SHIFT, .RIGHT_SHIFT},
	{.RIGHT_CONTROL, .RIGHT_CONTROL},
	{.RIGHT_ALT, .RIGHT_ALT},
	{.RIGHT_SUPER, .RIGHT_SUPER},
	{.KB_MENU, .KB_MENU},
	{.KP_0, .KP_0},
	{.KP_1, .KP_1},
	{.KP_2, .KP_2},
	{.KP_3, .KP_3},
	{.KP_4, .KP_4},
	{.KP_5, .KP_5},
	{.KP_6, .KP_6},
	{.KP_7, .KP_7},
	{.KP_8, .KP_8},
	{.KP_9, .KP_9},
	{.KP_DECIMAL, .KP_DECIMAL},
	{.KP_DIVIDE, .KP_DIVIDE},
	{.KP_MULTIPLY, .KP_MULTIPLY},
	{.KP_SUBTRACT, .KP_SUBTRACT},
	{.KP_ADD, .KP_ADD},
	{.KP_ENTER, .KP_ENTER},
	{.KP_EQUAL, .KP_EQUAL},
	{.BACK, .BACK},
	{.MENU, .MENU},
	{.VOLUME_UP, .VOLUME_UP},
	{.VOLUME_DOWN, .VOLUME_DOWN},
	// {.APOSTROPH, .APOSTROPH},
}

mouse_btn_to_check :: [?]RlToGameMouseMap {
	{.LEFT, .LEFT},
	{.RIGHT, .RIGHT},
	{.MIDDLE, .MIDDLE},
	{.SIDE, .SIDE},
	{.EXTRA, .EXTRA},
	{.FORWARD, .FORWARD},
	{.BACK, .BACK},
}

// Returns the current user input, frame id is zero
get_current_user_input :: proc() -> (new_input: UserInput) {
	new_input.meta = FrameMeta {
		0,
		rl.GetFrameTime(),
		cast(f32)rl.GetScreenWidth(),
		cast(f32)rl.GetScreenHeight(),
	}


	key_pressed := rl.GetKeyPressed()
	for key in keys_to_check {
		if rl.IsKeyDown(key.rl_key) {
			new_input.keyboard += {key.game_key}
		}
	}

	new_input.mouse.pos = cast(math.Vector2f32)(rl.GetMousePosition())
	for btn in mouse_btn_to_check {
		if rl.IsMouseButtonDown(btn.rl_btn) {
			new_input.mouse.buttons += {btn.game_btn}
		}
	}

	return new_input
}

update_input :: proc(frame_input: ^FrameInput) {
	next_frame: UserInput = get_current_user_input()
	next_frame.meta.frame_id = frame_input.current_frame.meta.frame_id + 1
	frame_input.last_frame = frame_input.current_frame
	frame_input.current_frame = next_frame
}
