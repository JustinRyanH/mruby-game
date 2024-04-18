package main

import "./utils"

import "core:fmt"
import "core:os"

AssetError :: enum {
	NoAssetError,
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

AssetSystem :: struct {
	ruby: map[RubyCodeHandle]RubyCode,
}

asset_system_init :: proc(as: ^AssetSystem) {
	as.ruby = make(map[RubyCodeHandle]RubyCode, 32)
}

asset_system_deinit :: proc(as: ^AssetSystem) {
	delete(as.ruby)
}

asset_system_load_ruby :: proc(as: ^AssetSystem, file: string) {
	handle := ruby_code_handle(file)
	if handle in as.ruby {
		// TODO: Reload if the mod time has changed
		panic("Unimplemented")
	}

	write_time, write_time_err := os.last_write_time_by_name(file)
	if write_time_err != os.ERROR_NONE {
		// TODO: Return error over panic
		panic(fmt.tprintf("Filed to access %s with err %v", file, write_time_err))
	}

	ruby_code, read_ruby_code_success := os.read_entire_file(file)
	assert(read_ruby_code_success, fmt.tprintf("Failed to open %s", file))

	code := RubyCode{handle, file, cast(u64)write_time, string(ruby_code)}
	as.ruby[handle] = code
}

asset_system_find_ruby :: proc(as: ^AssetSystem, handle: RubyCodeHandle) -> (RubyCode, bool) {
	return as.ruby[handle]
}
