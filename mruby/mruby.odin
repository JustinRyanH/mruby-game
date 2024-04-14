package mruby

when ODIN_OS == .Darwin {
	foreign import lib "venodor/darwin/libmruby.a"
}

State :: struct {}


@(link_prefix = "mrb_")
@(default_calling_convention = "c")
foreign lib {
	open :: proc() -> ^State ---
}
