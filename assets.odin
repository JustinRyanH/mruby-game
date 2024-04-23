package main

import "core:fmt"
import "core:os"

import rl "vendor:raylib"

import "./utils"


FontHandle :: distinct u64

FontAsset :: struct {
	handle: FontHandle,
	font:   rl.Font,
}

RubyCodeHandle :: distinct u64

ruby_code_handle :: proc(str: string) -> RubyCodeHandle {
	return cast(RubyCodeHandle)utils.generate_u64_from_string(str)

}

RubyCode :: struct {
	id:            RubyCodeHandle,
	file_path:     string,
	last_mod_time: u64,
	code:          string,
}

// @return true if successful
ruby_code_load :: proc(rc: ^RubyCode) -> bool {
	write_time, write_time_err := os.last_write_time_by_name(rc.file_path)
	if write_time_err != os.ERROR_NONE {
		panic(fmt.tprintf("Filed to access %s with err %v", rc.file_path, write_time_err))
	}
	if cast(u64)write_time <= rc.last_mod_time {
		return false
	}
	rc.last_mod_time = cast(u64)write_time

	if len(rc.code) > 0 {
		delete(rc.code)
	}

	ruby_code, read_ruby_code_success := os.read_entire_file(rc.file_path)
	assert(read_ruby_code_success, fmt.tprintf("Failed to open %s", rc.file_path))

	rc.code = string(ruby_code)
	return true
}

ruby_code_deinit :: proc(rc: ^RubyCode) {
	delete(rc.code)
}

AssetSystem :: struct {
	ruby: map[RubyCodeHandle]RubyCode,
}

asset_system_init :: proc(as: ^AssetSystem) {
	as.ruby = make(map[RubyCodeHandle]RubyCode, 32)
}

asset_system_deinit :: proc(as: ^AssetSystem) {
	for i in as.ruby {
		rc := &as.ruby[i]
		ruby_code_deinit(rc)
	}
	delete(as.ruby)
}

asset_system_load_ruby :: proc(as: ^AssetSystem, file: string) -> (RubyCodeHandle, bool) {
	handle := ruby_code_handle(file)
	if handle in as.ruby {
		rc: RubyCode
		ruby_code_load(&rc)
		return handle, true
	}

	rc: RubyCode
	rc.id = handle
	rc.file_path = file

	ruby_code_load(&rc)

	as.ruby[handle] = rc
	return handle, true
}

asset_system_find_ruby :: proc(as: ^AssetSystem, handle: RubyCodeHandle) -> (RubyCode, bool) {
	return as.ruby[handle]
}

asset_system_check :: proc(as: ^AssetSystem) {
	for i in as.ruby {
		rc := &as.ruby[i]
		ruby_code_load(rc)
	}
}

asset_get_font :: proc(as: ^AssetSystem, fh: FontHandle) -> FontAsset {
	if fh == 0 {
		return FontAsset{0, rl.GetFontDefault()}
	}
	unimplemented("Font AssetSystem not implemented")
}
