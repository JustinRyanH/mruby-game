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


color_pallet_to_color :: proc "contextless" (c: ColorPallet) -> (color: rl.Color) {
	switch c {
	case .LightGray:
		color = rl.LIGHTGRAY
	case .Gray:
		color = rl.GRAY
	case .DarkGray:
		color = rl.DARKGRAY
	case .Yellow:
		color = rl.YELLOW
	case .Gold:
		color = rl.GOLD
	case .Orange:
		color = rl.ORANGE
	case .Pink:
		color = rl.PINK
	case .Red:
		color = rl.RED
	case .Maroon:
		color = rl.MAROON
	case .Green:
		color = rl.GREEN
	case .Lime:
		color = rl.LIME
	case .DarkGreen:
		color = rl.DARKGREEN
	case .SkyBlue:
		color = rl.SKYBLUE
	case .Blue:
		color = rl.BLUE
	case .DarkBlue:
		color = rl.DARKBLUE
	case .Purple:
		color = rl.PURPLE
	case .Violet:
		color = rl.VIOLET
	case .DarkPurple:
		color = rl.DARKPURPLE
	case .Beige:
		color = rl.BEIGE
	case .Brown:
		color = rl.BROWN
	case .DarkBrown:
		color = rl.DARKBROWN
	case .White:
		color = rl.WHITE
	case .Black:
		color = rl.BLACK
	case .Blank:
		color = rl.BLANK
	case .Magenta:
		color = rl.MAGENTA
	case .RayWhite:
		color = rl.RAYWHITE
	}
	return
}

color_pallet_from_snake :: proc(str: string) -> (ColorPallet, bool) {
	v := strings.to_pascal_case(str, context.temp_allocator)
	return reflect.enum_from_name(ColorPallet, v)
}
