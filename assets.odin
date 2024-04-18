package main

import "./utils"

import "core:fmt"
import "core:os"


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

	ruby_code, read_ruby_code_success := os.read_entire_file(rc.file_path)
	assert(read_ruby_code_success, fmt.tprintf("Failed to open %s", rc.file_path))
	rc.code = string(ruby_code)
	fmt.println(rc.code)
	return true
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

	rc: RubyCode
	rc.id = handle
	rc.file_path = file

	ruby_code_load(&rc)

	as.ruby[handle] = rc
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
