package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

import rl "vendor:raylib"

import dp "./data_pool"
import rp "./rect_pack"
import "./utils"

ShaderHandle :: distinct dp.Handle

ShaderAsset :: struct {
	handle:    ShaderHandle,
	frag_path: Maybe(string),
	vert_path: Maybe(string),
	shader:    rl.Shader,
}

SoundHandle :: distinct u64

wave_handle :: proc(str: string) -> SoundHandle {
	return cast(SoundHandle)utils.generate_u64_from_string(str)
}

SoundAsset :: struct {
	handle: SoundHandle,
	sound:  rl.Sound,
}

TextureHandle :: distinct u64
AtlasHandle :: distinct u64

@(private = "file")
texture_handle :: proc(str: string) -> TextureHandle {
	return cast(TextureHandle)utils.generate_u64_from_string(str)
}

@(private = "file")
atlas_handle :: proc(str: string) -> AtlasHandle {
	return cast(AtlasHandle)utils.generate_u64_from_string(str)
}

TextureSystem :: struct {
	atlas_map: map[AtlasHandle]rl.Texture,
	textures:  map[TextureHandle]TextureAsset,
}


TextureAsset :: struct {
	handle:        TextureHandle,
	texture:       rl.Texture,
	src:           rl.Rectangle,
	atlas_texture: AtlasHandle,
}

texture_asset_deinit :: proc(ta: ^TextureAsset) {
	if ta.atlas_texture > 0 {
		return
	}
	rl.UnloadTexture(ta.texture)
}

FontHandle :: distinct u64

font_handle :: proc(str: string) -> FontHandle {
	return cast(FontHandle)utils.generate_u64_from_string(str)
}

FontAsset :: struct {
	handle: FontHandle,
	font:   rl.Font,
}

RubyCodeHandle :: distinct u64

ruby_code_handle :: proc(str: string) -> RubyCodeHandle {
	return cast(RubyCodeHandle)utils.generate_u64_from_string(str)
}

RubyCodeAsset :: struct {
	id:              RubyCodeHandle,
	file_path:       string,
	system_mod_time: u64,
	last_load_time:  i64,
	last_run_time:   i64,
	code:            string,
}

// @return true if successful
ruby_code_load :: proc(rc: ^RubyCodeAsset) -> bool {
	write_time, write_time_err := os.last_write_time_by_name(rc.file_path)
	if write_time_err != os.ERROR_NONE {
		panic(fmt.tprintf("Filed to access %s with err %v", rc.file_path, write_time_err))
	}
	if cast(u64)write_time <= rc.system_mod_time {
		return false
	}
	rc.system_mod_time = cast(u64)write_time
	rc.last_load_time = time.to_unix_nanoseconds(time.now())

	if len(rc.code) > 0 {
		delete(rc.code)
	}

	ruby_code, read_ruby_code_success := os.read_entire_file(rc.file_path)
	assert(read_ruby_code_success, fmt.tprintf("Failed to open %s", rc.file_path))
	rl.TraceLog(.INFO, fmt.ctprintf("[Re]Load File: %s", rc.file_path))

	rc.code = string(ruby_code)
	return true
}

ruby_code_deinit :: proc(rc: ^RubyCodeAsset) {
	delete(rc.file_path)
	delete(rc.code)
}

AssetSystem :: struct {
	asset_dir:      string,
	ruby:           map[RubyCodeHandle]RubyCodeAsset,
	fonts:          map[FontHandle]FontAsset,
	texture_system: TextureSystem,
	sounds:         map[SoundHandle]SoundAsset,
	shaders:        dp.DataPool(8, ShaderAsset, ShaderHandle),
}

as_init :: proc(as: ^AssetSystem, asset_dir: string) {
	as.ruby = make(map[RubyCodeHandle]RubyCodeAsset)
	as.fonts = make(map[FontHandle]FontAsset)
	as.sounds = make(map[SoundHandle]SoundAsset)
	as.asset_dir = asset_dir
}

as_deinit :: proc(as: ^AssetSystem) {
	for i in as.texture_system.textures {
		tx := &as.texture_system.textures[i]
		texture_asset_deinit(tx)
	}
	for i in as.ruby {
		rc := &as.ruby[i]
		ruby_code_deinit(rc)
	}

	for hndle in as.sounds {
		snd := &as.sounds[hndle]
		rl.UnloadSound(snd.sound)
	}

	delete(as.ruby)
	delete(as.fonts)
	delete(as.asset_dir)
	delete(as.texture_system.textures)
	delete(as.texture_system.atlas_map)
	delete(as.sounds)
}

as_load_ruby :: proc(as: ^AssetSystem, file: string) -> (RubyCodeHandle, bool) {
	handle := ruby_code_handle(file)
	if !(handle in as.ruby) {
		rc: RubyCodeAsset
		rc.id = handle
		rc.file_path = strings.clone(file)
		as.ruby[handle] = rc
	}

	rc, success := &as.ruby[handle]
	assert(success)
	ruby_code_load(rc)

	return handle, true
}

as_find_ruby :: proc(as: ^AssetSystem, handle: RubyCodeHandle) -> (RubyCodeAsset, bool) {
	return as.ruby[handle]
}

as_update_ruby_runtume :: proc(as: ^AssetSystem, handle: RubyCodeHandle) -> bool {
	rc, success := &as.ruby[handle]
	if !success {
		return false
	}
	rc.last_run_time = time.to_unix_nanoseconds(time.now())

	return true
}

as_should_rerun_ruby :: proc(as: ^AssetSystem, handle: RubyCodeHandle) -> bool {
	rc, success := as.ruby[handle]
	if !success {
		return false
	}
	return rc.last_load_time > rc.last_run_time
}

as_check :: proc(as: ^AssetSystem) {
	for i in as.ruby {
		rc := &as.ruby[i]
		ruby_code_load(rc)
	}
}

// TODO: Replace with proper error
as_load_font :: proc(as: ^AssetSystem, path: string) -> (FontHandle, bool) {
	handle := font_handle(path)
	if handle in as.fonts {
		// TODO: Check if the file has change and reload
		return handle, true
	}

	cpath := strings.clone_to_cstring(path, context.temp_allocator)

	font := rl.LoadFontEx(cpath, 96, nil, 0)
	if font == {} {
		return {}, false
	}
	fa := FontAsset{handle, font}
	as.fonts[handle] = fa

	return handle, true
}

as_get_font :: proc(as: ^AssetSystem, fh: FontHandle) -> FontAsset {
	if fh == 0 {
		return FontAsset{0, rl.GetFontDefault()}
	}
	fa, success := as.fonts[fh]
	if !success {
		return FontAsset{0, rl.GetFontDefault()}
	}
	return fa
}

as_load_texture :: proc(as: ^AssetSystem, path: string) -> (TextureHandle, bool) {
	th := texture_handle(path)
	if th in as.texture_system.textures {
		return th, true
	}

	cpath := strings.clone_to_cstring(path, context.temp_allocator)

	texture := rl.LoadTexture(cpath)
	if !rl.IsTextureReady(texture) {
		return 0, false
	}
	src := rl.Rectangle{0, 0, cast(f32)texture.width, cast(f32)texture.height}
	assert(texture != {})
	as.texture_system.textures[th] = TextureAsset{th, texture, src, 0}

	return th, true
}

// TODO: More complex failure information
as_create_atlas_from_paths :: proc(
	as: ^AssetSystem,
	name: string,
	width, height: i32,
	paths: []string,
) -> (
	AtlasHandle,
	bool,
) {
	ah := atlas_handle(name)
	if ah in as.texture_system.atlas_map {
		return 0, false
	}
	img := rl.GenImageColor(width, height, rl.BLANK)
	defer rl.UnloadImage(img)

	rects: []rp.Rect = make([]rp.Rect, len(paths), context.temp_allocator)
	images: []rl.Image = make([]rl.Image, len(paths), context.temp_allocator)
	nodes := make([]rp.Node, len(paths), context.temp_allocator)

	for path, idx in paths {
		cpath := strings.clone_to_cstring(path, context.temp_allocator)
		img := rl.LoadImage(cpath)
		images[idx] = img

		rects[idx].id = idx
		rects[idx].w = img.width + 2
		rects[idx].h = img.height + 2
	}

	defer {
		for image in images {
			rl.UnloadImage(image)
		}
	}

	ctx := rp.Context{}
	rp.init_target(&ctx, width, height, nodes)
	rp.pack_rects(&ctx, rects)

	for rect, idx in rects {
		target := images[idx]
		w, h := cast(f32)target.width, cast(f32)target.height
		x, y := cast(f32)rect.x, cast(f32)rect.y
		assert(rect.id == idx, "Packed Rectangle got unsorted")
		rl.ImageDraw(&img, target, {0, 0, w, h}, {x + 1, y + 1, w, h}, rl.WHITE)
		// Left Padding
		rl.ImageDraw(&img, target, {0, 0, 1, h}, {x, y + 1, 1, h}, rl.WHITE)
		// Right Padding
		rl.ImageDraw(&img, target, {w - 1, 0, 1, h}, {x + w + 1, y + 1, 1, h}, rl.WHITE)

		// Top Padding
		rl.ImageDraw(&img, target, {0, 0, w, 1}, {x + 1, y, w, 1}, rl.WHITE)
		// Bottom Padding
		rl.ImageDraw(&img, target, {0, h - 1, w, 1}, {x + 1, y + h + 1, w, 1}, rl.WHITE)
	}


	atlas_texture := rl.LoadTextureFromImage(img)
	rl.SetTextureWrap(atlas_texture, .CLAMP)

	for image, idx in images {
		path := paths[idx]
		rect := rects[idx]

		w, h := cast(f32)rect.w - 2, cast(f32)rect.h - 2
		x, y := cast(f32)rect.x + 1, cast(f32)rect.y + 1

		handle := texture_handle(path)

		if handle in as.texture_system.textures {
			texture_asset_deinit(&as.texture_system.textures[handle])
		}

		asset: TextureAsset
		asset.handle = handle
		asset.texture = atlas_texture
		asset.src = {x, y, w, h}
		asset.atlas_texture = ah
		as.texture_system.textures[handle] = asset
	}

	// TODO: Thing
	as.texture_system.atlas_map[ah] = atlas_texture

	return ah, true
}

as_get_atlas_texture :: proc(as: ^AssetSystem, ah: AtlasHandle) -> (rl.Texture, bool) {
	if !(ah in as.texture_system.atlas_map) {
		return {}, false
	}

	return as.texture_system.atlas_map[ah]
}

as_get_texture :: proc(as: ^AssetSystem, th: TextureHandle) -> (TextureAsset, bool) {
	if !(th in as.texture_system.textures) {
		return {}, false
	}

	return as.texture_system.textures[th]
}

as_get_texture_ptr :: proc(as: ^AssetSystem, th: TextureHandle) -> ^TextureAsset {
	if !(th in as.texture_system.textures) {
		return nil
	}

	return &as.texture_system.textures[th]
}

as_load_sound :: proc(as: ^AssetSystem, path: string) -> (SoundHandle, bool) {
	sh := wave_handle(path)
	if sh in as.sounds {
		return sh, true
	}

	cpath := strings.clone_to_cstring(path, context.temp_allocator)

	sound := rl.LoadSound(cpath)
	assert(sound != {})
	as.sounds[sh] = SoundAsset{sh, sound}

	return sh, true
}

as_get_sound :: proc(as: ^AssetSystem, sh: SoundHandle) -> (SoundAsset, bool) {
	if sh == 0 {
		return {}, false
	}
	return as.sounds[sh]
}

// TODO: unload shader
as_load_shader :: proc(
	as: ^AssetSystem,
	vert_path, frag_path: Maybe(string),
) -> (
	ShaderHandle,
	bool,
) {
	iter := dp.new_iter(&as.shaders)
	for data, handle in dp.iter_next(&iter) {
		if data.frag_path == frag_path && data.vert_path == vert_path {
			return handle, true
		}
	}

	c_vert_path: cstring = t_maybe_path_to_cstring(vert_path)
	c_frag_path: cstring = t_maybe_path_to_cstring(frag_path)

	shader := rl.LoadShader(c_vert_path, c_frag_path)
	assert(rl.IsShaderReady(shader), "Shader Did not load")
	shader_asset, handle, success := dp.add_empty(&as.shaders)
	if (!success) {
		return {}, false
	}
	shader_asset.frag_path = frag_path
	shader_asset.vert_path = vert_path
	shader_asset.handle = handle
	shader_asset.shader = shader

	return handle, true
}

as_get_shader :: proc(as: ^AssetSystem, handle: ShaderHandle) -> (ShaderAsset, bool) #optional_ok {
	iter := dp.new_iter(&as.shaders)
	for data, maybe_handle in dp.iter_next(&iter) {
		if handle == maybe_handle {
			return data, true
		}
	}

	return {}, false
}

@(private = "file")
t_maybe_path_to_cstring :: proc(path: Maybe(string)) -> cstring {
	p, ok := path.(string)
	if !ok {
		return nil
	}

	return strings.clone_to_cstring(p, context.temp_allocator)
}
