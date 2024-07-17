package main

import "base:runtime"

import "core:fmt"
import math "core:math/linalg"
import "core:mem"
import "core:reflect"
import "core:slice"
import "core:strings"

import rl "vendor:raylib"

import dp "./data_pool"
import "./input"
import mrb "./mruby"
import rb "./ring_buffer"

GAME_DEV :: #config(GAME_DEV, true)

Vector2 :: rl.Vector2
Color :: rl.Color

debug_print_mrb_obj :: proc(game: ^Game) {
	fmt.println("Live Objects", mrb.gc_get_live(game.ruby), "State", mrb.gc_get_state(game.ruby))
	fmt.println(
		"Threshold",
		mrb.gc_get_threshold(game.ruby),
		"Live After:",
		mrb.gc_get_live_after_mark(game.ruby),
	)
}

mruby_odin_allocf :: proc "c" (
	state: ^mrb.State,
	ptr: rawptr,
	size: uint,
	user_data: rawptr,
) -> rawptr {
	ctx := transmute(^runtime.Context)user_data
	context = ctx^
	ptr_as_num := transmute(uint)ptr

	if size == 0 && ptr == nil {
		return nil
	}
	if ptr == nil {
		n_ptr, err := mem.alloc(cast(int)size)
		assert(err == .None, "Allocation Error")
		ptr_as_num := transmute(uint)n_ptr
		return n_ptr
	}
	if size == 0 {
		mem.free(ptr)
		return nil
	}

	info := mem.query_info(ptr, context.allocator)
	old_size, ok := info.size.(int)
	assert(ok, "Cannot resize if we didn't track the old size")
	n_ptr, err := mem.resize(ptr, old_size, cast(int)size)
	assert(err == .None, "Allocation Error")

	return n_ptr
}

MrubyCtx :: struct {
	ctx: runtime.Context,
}

reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> (err: bool) {
	for _, value in a.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
		err = true
	}
	mem.tracking_allocator_clear(a)
	return
}

track_bad_free_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> (err: bool) {
	for b in a.bad_free_array {
		fmt.println("Bad Free at: %v", b.location)
		err = true
	}
	return
}

TargetFPS :: 60

game_run_code :: proc(game: ^Game, handle: RubyCodeHandle, loc := #caller_location) {
	code, found := as_find_ruby(&game.assets, handle)
	assert(found, "Ruby Code not found")
	v := mrb.load_string(g.ruby, code.code)
	as_update_ruby_runtume(&game.assets, handle)

	if mrb.state_get_exc(g.ruby) != nil {
		mrb.print_backtrace(g.ruby)
	}
	assert(mrb.state_get_exc(g.ruby) == nil, "There should be no exceptions")
}

game_ctx: runtime.Context

game_draw_renderables :: proc(game: ^Game, renderables: []RenderableTexture) {
	slice.sort_by(
		renderables,
		proc(i, j: RenderableTexture) -> bool {return i.z_offset < j.z_offset},
	)

	{
		camera := game_get_camera(g)
		rl.BeginMode2D(camera)

		for renderable in todo_render {
			renderable_texture_render(renderable)
		}

		game_debug_draw(g)
		rl.EndMode2D()
	}
}


RenderableTexture :: struct {
	texture:   rl.Texture2D,
	src, dest: rl.Rectangle,
	offset:    rl.Vector2,
	tint:      rl.Color,
	rotation:  f32,
	z_offset:  f32,
}

renderable_from_sprint :: proc(
	game: ^Game,
	spr: Sprite,
) -> (
	out: RenderableTexture,
	success: bool,
) {
	asset, texture_success := as_get_texture(&game.assets, spr.texture)
	if !texture_success {
		return
	}

	p_offset := game_parallax_offset(game, spr.parallax)
	new_pos := spr.pos + p_offset

	out.texture = asset.texture
	out.src = asset.src
	out.dest = {new_pos.x, new_pos.y, spr.size.x, spr.size.y}
	out.tint = spr.tint
	out.offset = Vector2{spr.size.x * spr.anchor.x, spr.size.y * spr.anchor.y}
	out.rotation = 0
	out.z_offset = spr.z_offset

	return out, true
}

renderable_from_reveal_spot :: proc(
	game: ^Game,
	spot: RevealSpot,
) -> (
	out: RenderableTexture,
	success: bool,
) {
	asset, texture_success := as_get_texture(&game.assets, spot.texture)
	if !texture_success {
		return
	}


	out.texture = asset.texture
	out.src = asset.src
	out.dest = {
		spot.pos.x,
		spot.pos.y,
		cast(f32)asset.texture.width,
		cast(f32)asset.texture.height,
	}
	out.tint = rl.WHITE

	return out, true
}

renderable_texture_render :: proc(renderable: RenderableTexture) {
	rl.DrawTexturePro(
		renderable.texture,
		renderable.src,
		renderable.dest,
		renderable.offset,
		renderable.rotation,
		renderable.tint,
	)
}

todo_render: [dynamic]RenderableTexture

g: ^Game

SCREEN_HEIGHT :: 800
SCREEN_WIDTH :: 1280
SCALE_WIDTH :: SCREEN_WIDTH / 4
SCALE_HEIGHT :: SCREEN_HEIGHT / 4
main :: proc() {
	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	defer mem.tracking_allocator_destroy(&tracking_allocator)

	context.allocator = mem.tracking_allocator(&tracking_allocator)
	defer reset_tracking_allocator(&tracking_allocator)

	game_ctx = context


	g = new(Game)
	defer free(g)

	game_init(g)
	defer game_deinit(g)

	game_load_mruby_raylib(g)

	tick_handle, tick_loaded := as_load_ruby(&g.assets, "rb/tick.rb")
	assert(tick_loaded, "`tick.rb` is required")

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin-Ruby Game Demo")
	defer rl.CloseWindow()

	when GAME_DEV {
		// TODO: Clean this up on release
		rl.SetWindowMonitor(1)
	}

	shader, shader_loaded := as_load_shader(&g.assets, nil, "assets/shaders/simple.frag")
	assert(shader_loaded, "Failed to load shader")

	screen_buffer := rl.LoadRenderTexture(SCALE_WIDTH, SCALE_HEIGHT)
	static_element_buffer := rl.LoadRenderTexture(SCALE_WIDTH, SCALE_HEIGHT)
	static_element_effect_buffer := rl.LoadRenderTexture(SCALE_WIDTH, SCALE_HEIGHT)

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	rl.SetTargetFPS(TargetFPS)

	for !g.should_exit {
		defer {
			is_bad := track_bad_free_tracking_allocator(&tracking_allocator)
			assert(!is_bad, "Double Free issue")
		}
		defer free_all(context.temp_allocator)
		defer mrb.incremental_gc(g.ruby)
		defer game_handle_sounds(g)
		todo_render = make([dynamic]RenderableTexture, 0, 1024, context.temp_allocator)


		imui_begin(&g.imui)

		game_setup_temp(g)

		input.update_input(&g.input, 1.0 / TargetFPS)
		g.input.current_frame.meta.screen_width = SCALE_WIDTH
		g.input.current_frame.mouse.pos *= 1.0 / 4.0
		g.input.current_frame.meta.screen_height = SCALE_HEIGHT

		game_check_collisions(g)
		game_run_code(g, tick_handle)

		rl.BeginDrawing()


		{
			rl.BeginTextureMode(static_element_buffer)
			defer rl.EndTextureMode()
			rl.ClearBackground(rl.BLANK)

			sprt_iter := dp.new_iter(&g.sprites)
			for spr in dp.iter_next(&sprt_iter) {
				if !spr.visible {continue}
				if spr.type != .Static {continue}
				renderable, success := renderable_from_sprint(g, spr)
				if (!success) {
					rl.TraceLog(.WARNING, "Could not Render Sprite")
					continue
				}
				append(&todo_render, renderable)
			}
			game_draw_renderables(g, todo_render[:])


		}
		clear(&todo_render)

		{
			rl.BeginTextureMode(static_element_effect_buffer)
			rl.ClearBackground(rl.BLANK)
			defer rl.EndTextureMode()

			reveal_iter := rb.new_iter(&g.reveal_spots)
			for spot in rb.iter_next(&reveal_iter) {
				renderable, success := renderable_from_reveal_spot(g, spot)
				if !success {
					continue
				}
				append(&todo_render, renderable)
			}

			game_draw_renderables(g, todo_render[:])
		}
		clear(&todo_render)

		{
			rl.BeginTextureMode(screen_buffer)
			rl.ClearBackground(rl.BLANK)


			sprt_iter := dp.new_iter(&g.sprites)
			for spr in dp.iter_next(&sprt_iter) {
				if !spr.visible {continue}
				if spr.type != .Dynamic {continue}
				renderable, success := renderable_from_sprint(g, spr)
				if (!success) {
					rl.TraceLog(.WARNING, "Could not Render Sprite")
					continue
				}
				append(&todo_render, renderable)
			}
			game_draw_renderables(g, todo_render[:])

			imui_draw(&g.imui)

			rl.EndTextureMode()
		}

		rl.ClearBackground(g.bg_color)
		{
			shader_asset := as_get_shader(&g.assets, shader)

			rl.BeginShaderMode(shader_asset.shader)
			texture1_loc := rl.GetShaderLocation(shader_asset.shader, "texture1")

			rl.SetShaderValueTexture(
				shader_asset.shader,
				texture1_loc,
				static_element_effect_buffer.texture,
			)

			rl.DrawTexturePro(
				static_element_buffer.texture,
				{0, -SCALE_HEIGHT, SCALE_WIDTH, -SCALE_HEIGHT},
				{0, 0, SCREEN_WIDTH, SCREEN_HEIGHT},
				rl.Vector2{},
				0,
				rl.WHITE,
			)

			defer rl.EndShaderMode()
		}
		rl.DrawTexturePro(
			screen_buffer.texture,
			{0, -SCALE_HEIGHT, SCALE_WIDTH, -SCALE_HEIGHT},
			{0, 0, SCREEN_WIDTH, SCREEN_HEIGHT},
			rl.Vector2{},
			0,
			rl.WHITE,
		)

		rl.DrawText(fmt.ctprintf("Sprites: %d", dp.length(&g.sprites)), 100, 100, 32, rl.RED)
		rl.DrawText(fmt.ctprintf("FPS: %d", rl.GetFPS()), 100, 140, 32, rl.RED)

		rl.EndDrawing()

		// Check for asset change every second or so
		if input.frame_query_id(g.input) % TargetFPS == 0 {
			as_check(&g.assets)
		}
		if rl.WindowShouldClose() {
			g.should_exit = true
		}
	}
}
