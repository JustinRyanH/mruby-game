package main

import "core:reflect"
import "core:strings"

import rl "vendor:raylib"

import mrb "./mruby"


ColorPallet :: enum {
	Blank,
	LightGray,
	Gray,
	DarkGray,
	Yellow,
	Gold,
	Orange,
	Pink,
	Red,
	Maroon,
	Green,
	Lime,
	DarkGreen,
	SkyBlue,
	Blue,
	DarkBlue,
	Purple,
	Violet,
	DarkPurple,
	Beige,
	Brown,
	DarkBrown,
	White,
	Black,
	Magenta,
	RayWhite,
}

pallet_to_color := [ColorPallet]rl.Color {
	.LightGray  = rl.LIGHTGRAY,
	.Gray       = rl.GRAY,
	.DarkGray   = rl.DARKGRAY,
	.Yellow     = rl.YELLOW,
	.Gold       = rl.GOLD,
	.Orange     = rl.ORANGE,
	.Pink       = rl.PINK,
	.Red        = rl.RED,
	.Maroon     = rl.MAROON,
	.Green      = rl.GREEN,
	.Lime       = rl.LIME,
	.DarkGreen  = rl.DARKGREEN,
	.SkyBlue    = rl.SKYBLUE,
	.Blue       = rl.BLUE,
	.DarkBlue   = rl.DARKBLUE,
	.Purple     = rl.PURPLE,
	.Violet     = rl.VIOLET,
	.DarkPurple = rl.DARKPURPLE,
	.Beige      = rl.BEIGE,
	.Brown      = rl.BROWN,
	.DarkBrown  = rl.DARKBROWN,
	.White      = rl.WHITE,
	.Black      = rl.WHITE,
	.Blank      = rl.BLANK,
	.Magenta    = rl.MAGENTA,
	.RayWhite   = rl.RAYWHITE,
}


color_pallet_from_snake :: proc(str: string) -> (ColorPallet, bool) {
	v := strings.to_pascal_case(str, context.temp_allocator)
	return reflect.enum_from_name(ColorPallet, v)
}
