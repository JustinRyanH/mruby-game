package main

import rl "vendor:raylib"

TextAlignment :: enum {
	Left,
	Right,
	Center,
}

ImuiDrawTextCmd :: struct {
	font:      FontHandle,
	txt:       cstring,
	alignment: TextAlignment,
	size:      f32,
	spacing:   f32,
	color:     Color,
	pos:       Vector2,
}

ImuiCommand :: union {
	ImuiDrawTextCmd,
}

ImUiState :: struct {
	cmd_buffer_t: [dynamic]ImuiCommand,
}

imui_beign :: proc(imui: ^ImUiState) {
	imui.cmd_buffer_t = make([dynamic]ImuiCommand, 32, context.temp_allocator)
}

imui_add_cmd :: proc(imui: ^ImUiState, cmd: ImuiCommand) {
	append(&imui.cmd_buffer_t, cmd)
}

imui_draw :: proc(imui: ^ImUiState) {
	assets := &g.assets
	for cmd in imui.cmd_buffer_t {
		switch c in cmd {
		case ImuiDrawTextCmd:
			ft := asset_get_font(assets, c.font)
			// TODO: Implement ALignment, Rotation
			rl.DrawTextPro(ft.font, c.txt, c.pos, {}, 0, c.size, c.spacing, c.color)
		}
	}
}
