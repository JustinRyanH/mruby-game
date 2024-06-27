package main

import "core:fmt"
import "core:math"
import "core:strings"
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
	font:    FontHandle,
	txt:     cstring,
	halign:  HorizontalAlignment,
	size:    f32,
	spacing: f32,
	color:   Color,
	pos:     Vector2,
}

ImuiDrawRectCmd :: struct {
	pos:      Vector2,
	size:     Vector2,
	offset_p: Vector2,
	color:    Color,
	mode:     DrawMode,
}

DrawableTextureHandle :: union {
	TextureHandle,
	AtlasHandle,
}


ImUiDrawTextureCmd :: struct {
	pos:      Vector2,
	size:     Vector2,
	offset_p: Vector2,
	texture:  DrawableTextureHandle,
	rotation: f32,
	tint:     Color,
}


ImuiDrawLineCmd :: struct {
	start:     Vector2,
	end:       Vector2,
	thickness: f32,
	color:     Color,
}

ImuiScissorBegin :: struct {
	left:   i32,
	top:    i32,
	width:  i32,
	height: i32,
}

ImuiScissorEnd :: struct {}

ImuiCommand :: union {
	ImuiDrawTextCmd,
	ImuiDrawRectCmd,
	ImuiDrawLineCmd,
	ImUiDrawTextureCmd,
	ImuiScissorBegin,
	ImuiScissorEnd,
}

ImUiState :: struct {
	cmd_buffer_t: [dynamic]ImuiCommand,
}

imui_begin :: proc(imui: ^ImUiState) {
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
			txt := c.txt
			ft := as_get_font(assets, c.font)
			measure := rl.MeasureTextEx(ft.font, txt, c.size, c.spacing)
			offset := alignment_offset(c.halign, measure)
			rl.DrawTextPro(ft.font, txt, c.pos, offset, 0, c.size, c.spacing, c.color)
		case ImuiDrawRectCmd:
			rect: rl.Rectangle
			rect.width = c.size.x
			rect.height = c.size.y

			rect.y = c.pos.y - c.size.y * c.offset_p.y
			rect.x = c.pos.x - c.size.x * c.offset_p.x

			switch c.mode {
			case .Solid:
				rl.DrawRectangleRec(rect, c.color)
			case .Outline:
				rl.DrawRectangleLinesEx(rect, 2, c.color)
			}
		case ImuiDrawLineCmd:
			rl.DrawLineEx(c.start, c.end, c.thickness, c.color)
		case ImUiDrawTextureCmd:
			switch handle in c.texture {
			case TextureHandle:
				asset, success := as_get_texture(&g.assets, handle)
				assert(success, "We should not try to draw an invalid texture")

				offset := rl.Vector2{c.size.x * c.offset_p.x, c.size.y * c.offset_p.y}

				dest := rl.Rectangle{c.pos.x, c.pos.y, c.size.x, c.size.y}

				rl.DrawTexturePro(asset.texture, asset.src, dest, offset, c.rotation, c.tint)
			case AtlasHandle:
				atlas, success := as_get_atlas_texture(&g.assets, handle)
				assert(success, "We should not try to draw an invalid texture")

				offset := rl.Vector2{c.size.x * c.offset_p.x, c.size.y * c.offset_p.y}

				dest := rl.Rectangle{c.pos.x, c.pos.y, c.size.x, c.size.y}

				rl.DrawTexturePro(
					atlas,
					{0, 0, cast(f32)atlas.width, cast(f32)atlas.height},
					dest,
					offset,
					c.rotation,
					c.tint,
				)
			}
		case ImuiScissorBegin:
			rl.BeginScissorMode(c.left, c.top, c.width, c.height)
		case ImuiScissorEnd:
			rl.EndScissorMode()
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
