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
	// SLSO8
	CrowBlackBlue,
	RegalBlue,
	MagicSpell,
	BluntViolet,
	ApricotBrown,
	DreamySunset,
	Affinity,
	CrushedCashew,
}

pallet_to_color := [ColorPallet]Color {
	.LightGray     = rl.LIGHTGRAY,
	.Gray          = rl.GRAY,
	.DarkGray      = rl.DARKGRAY,
	.Yellow        = rl.YELLOW,
	.Gold          = rl.GOLD,
	.Orange        = rl.ORANGE,
	.Pink          = rl.PINK,
	.Red           = rl.RED,
	.Maroon        = rl.MAROON,
	.Green         = rl.GREEN,
	.Lime          = rl.LIME,
	.DarkGreen     = rl.DARKGREEN,
	.SkyBlue       = rl.SKYBLUE,
	.Blue          = rl.BLUE,
	.DarkBlue      = rl.DARKBLUE,
	.Purple        = rl.PURPLE,
	.Violet        = rl.VIOLET,
	.DarkPurple    = rl.DARKPURPLE,
	.Beige         = rl.BEIGE,
	.Brown         = rl.BROWN,
	.DarkBrown     = rl.DARKBROWN,
	.White         = rl.WHITE,
	.Black         = rl.BLACK,
	.Blank         = rl.BLANK,
	.Magenta       = rl.MAGENTA,
	.RayWhite      = rl.RAYWHITE,

	// SLSO8
	.CrowBlackBlue = {0x0d, 0x2b, 0x45, 0xFF},
	.RegalBlue     = {0x20, 0x3c, 0x56, 0xFF},
	.MagicSpell    = {0x54, 0x4e, 0x68, 0xFF},
	.BluntViolet   = {0x8d, 0x69, 0x7a, 0xFF},
	.ApricotBrown  = {0xd0, 0x81, 0x59, 0xFF},
	.DreamySunset  = {0xff, 0xaa, 0x5e, 0xFF},
	.Affinity      = {0xff, 0xd4, 0xa3, 0xFF},
	.CrushedCashew = {0xff, 0xec, 0xd6, 0xFF},
}


color_pallet_from_snake :: proc(str: string) -> (ColorPallet, bool) {
	v := strings.to_pascal_case(str, context.temp_allocator)
	return reflect.enum_from_name(ColorPallet, v)
}
