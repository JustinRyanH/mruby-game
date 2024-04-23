package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

VerticalAlignment :: enum {
	Top,
	Bottom,
	Center,
}

HorizontalAlignment :: enum {
	Left,
	Right,
	Center,
}

DrawMode :: enum {
	Solid,
	Outline,
}

ImuiDrawTextCmd :: struct {
	font:      FontHandle,
	txt:       cstring,
	// TODO: Rename to valign
	alignment: HorizontalAlignment,
	size:      f32,
	spacing:   f32,
	color:     Color,
	pos:       Vector2,
}

ImuiDrawRectCmd :: struct {
	pos:      Vector2,
	size:     Vector2,
	offset_p: Vector2,
	color:    Color,
	mode:     DrawMode,
}

ImuiCommand :: union {
	ImuiDrawTextCmd,
	ImuiDrawRectCmd,
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
			ft := asset_system_get_font(assets, c.font)
			measure := rl.MeasureTextEx(ft.font, c.txt, c.size, c.spacing)
			offset := alignment_offset(c.alignment, measure)
			rl.DrawTextPro(ft.font, c.txt, c.pos, offset, 0, c.size, c.spacing, c.color)
		case ImuiDrawRectCmd:
			rect: rl.Rectangle
			rect.width = c.size.x
			rect.height = c.size.y

			rect.y = c.pos.y + c.size.y * c.offset_p.y
			rect.x = c.pos.x + c.size.x * c.offset_p.y

			switch c.mode {
			case .Solid:
				rl.DrawRectangleRec(rect, c.color)
			case .Outline:
				rl.DrawRectangleLinesEx(rect, 2, c.color)
			}
		}

	}
}

@(private = "file")
alignment_offset :: proc(algn: HorizontalAlignment, measurement: Vector2) -> (offset: Vector2) {
	offset.y = measurement.y * 0.5
	switch algn {
	case .Left:
		offset.x = 0
	case .Center:
		offset.x = measurement.x * 0.5
	case .Right:
		offset.x = measurement.x
	}

	return
}
