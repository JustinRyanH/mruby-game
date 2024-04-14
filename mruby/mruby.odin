package mruby

when ODIN_OS == .Darwin {
	foreign import lib "vendor/darwin/libmruby.a"
}

Value :: struct {
	v: u64,
}

State :: struct {}


@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	open :: proc() -> ^State ---
}
