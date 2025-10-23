package pirc

// PIRC = Platform Independent Render Commands

import "core:math"
import "core:slice"
import "core:fmt"
import "../shape"


Texture_Id :: u32


Font_Id :: u32


Texture :: struct 
{
	id : u32,
	name : string,
	w, h : f32,
}


Cmd_Rectangle_Fill :: struct
{
	using rectangle : shape.Rectangle,
	color : [4]u8,
}


Cmd_Rectangle_Lines :: struct
{
	using rectangle : shape.Rectangle, 
	thick : f32,
	color : [4]u8,
}


Cmd_Line :: struct
{
	x1, x2, y1, y2 : f32,
	thick : f32,
	color : [4]u8,
}


Cmd_Texture_Clip :: struct
{
	tex_id : Texture_Id,
	src_rect : shape.Rectangle,
	dst_rect : shape.Rectangle,
	rotation : f32,
	rotation_origin : [2]f32,
	color : [4]u8,
	flip_x, flip_y : bool
}


Cmd_Clear :: struct 
{
	color : [4]u8
}


Cmd_Text :: struct
{
	pos : [2]f32,
	size : f32,
	font : Font_Id,
	color : [4]u8,
	text : string,
}


Cmd :: union 
{
	Cmd_Rectangle_Fill,
	Cmd_Rectangle_Lines,
	Cmd_Line,
	Cmd_Texture_Clip,
	Cmd_Text,
	Cmd_Clear,
}


V_Alignment :: enum { Top, Center, Bottom }
H_Alignment :: enum { Left, Center, Right }


render_bg_clear :: proc(cmds : ^[dynamic]Cmd, r, g, b, a : u8)
{
	cmd := Cmd_Clear { color = { r, g, b, a } }
	append(cmds, cmd)
}


render_rectangle_fill :: proc(cmds : ^[dynamic]Cmd, x, y, w, h : f32, r, g, b, a : u8)
{
	cmd := Cmd_Rectangle_Fill { x = x, y = y, w = w, h = h, color = { r, g, b, a } }
	append(cmds, cmd)
}


render_rectangle_lines :: proc(cmds : ^[dynamic]Cmd, x, y, w, h, thick : f32, r, g, b, a : u8)
{
	cmd := Cmd_Rectangle_Lines { x = x, y = y, w = w, h = h, thick = thick, color = { r, g, b, a } }
	append(cmds, cmd)
}


render_line :: proc(cmds : ^[dynamic]Cmd, x1, y1, x2, y2, thick : f32, r, g, b, a : u8)
{
	cmd := Cmd_Line { x1 = x1, y1 = y1, x2 = x2, y2 = y2, thick = thick, color = { r, g, b, a } }
	append(cmds, cmd)
}


render_texture :: proc(cmds : ^[dynamic]Cmd, texture : Texture, pos : [2]f32, color : [4]u8 = { 255, 255, 255, 255})
{
	cmd := Cmd_Texture_Clip { tex_id = texture.id, src_rect = { 0, 0, texture.w, texture.h }, dst_rect = {pos.x, pos.y, texture.w, texture.h }, color = color }
	append(cmds, cmd)
}

render_texture_ex :: proc(
	cmds : ^[dynamic]Cmd,
	texture : Texture,
	pos : [2]f32,
	scale : f32 = 1,
	color : [4]u8 = { 255, 255, 255, 255 },
)
{
	src_rect := shape.Rectangle {
		0,
		0,
		texture.w,
		texture.h,
	}

	dst_rect := shape.Rectangle {
		pos.x,
		pos.y,
		texture.w * scale,
		texture.h * scale,
	}

	render_texture_clip_ex(
		cmds, 
		texture, 
		src_rect.x, src_rect.y, src_rect.w, src_rect.h,
		dst_rect, 
		color = color,
	)	
}


render_texture_clip :: proc(cmds : ^[dynamic]Cmd, texture : Texture, pos : [2]f32, clip_x, clip_y, clip_w, clip_h : f32, color : [4]u8 = { 255, 255, 255, 255 } )
{
	cmd := Cmd_Texture_Clip { tex_id = texture.id, src_rect = { clip_x, clip_y, clip_w, clip_h }, dst_rect = { pos.x, pos.y, clip_w, clip_h }, color = color }
	append(cmds, cmd)
}


render_texture_clip_ex :: proc(
	cmds : ^[dynamic]Cmd, 
	texture : Texture, 
	clip_x, clip_y, clip_w, clip_h : f32,
	dst_rect : shape.Rectangle,
	color : [4]u8 = { 255, 255, 255, 255 },
	rotation : f32 = 0.0, 
	flip_x : bool = false, 
	flip_y : bool = false,
)
{
	src_rect := shape.Rectangle { clip_x, clip_y, clip_w, clip_h }
	if flip_x
	{
		src_rect.w = -src_rect.w
	}
	else if flip_y
	{
		src_rect.h = -src_rect.h
	}

	dst_rectangle := dst_rect
	rotation_origin := [2]f32{dst_rectangle.w / 2, dst_rectangle.h / 2}
	dst_rectangle.x += rotation_origin.x
	dst_rectangle.y += rotation_origin.y

	cmd := Cmd_Texture_Clip { 
		tex_id = texture.id, 
		src_rect = src_rect, 
		dst_rect = dst_rectangle,
		rotation = rotation,
		rotation_origin = rotation_origin,
		color = color 
	}

	append(cmds, cmd)
}


render_text_tprintf :: proc(cmds : ^[dynamic]Cmd, pos : [2]f32, font_id : Font_Id, size : f32, color : [4]u8 = { 255, 255, 255, 255 }, fmt_s : string, args : ..any)
{
	text := fmt.tprintf(fmt_s, ..args)
	cmd := Cmd_Text { pos = pos,
		size = size,
		font = font_id,
		color = color,
		text = text,
	}
	append(cmds, cmd)
}


grid_render_text_tprintf :: proc(cmds : ^[dynamic]Cmd, pos : [2]f32, font_id : Font_Id, size : f32, color : [4]u8, dst_grid_unit_size : f32, fmt_s : string, args : ..any)
{
	dst_pos := pos * dst_grid_unit_size
	dst_size := size * dst_grid_unit_size
	render_text_tprintf(
		cmds,
		dst_pos,
		font_id,
		dst_size,
		color,
		fmt_s,
		..args
	) 
}

grid_render_texture_clip :: proc(
	cmds : ^[dynamic]Cmd,
	tex : Texture,
	src_rect: shape.Rectangle,
	dst_rect : shape.Rectangle,
	src_grid_unit_size : f32 = 1.0,
	dst_grid_unit_size : f32 = 1.0, 
	color : [4]u8 = {255, 255, 255, 255}, 
	rotation : f32 = 0.0, 
	flip_x : bool = false, 
	flip_y : bool = false
)
{
	dst_grid_rect := shape.Rectangle {
		dst_rect.x * dst_grid_unit_size,
		dst_rect.y * dst_grid_unit_size,
		dst_rect.w * dst_grid_unit_size,
		dst_rect.h * dst_grid_unit_size,
	}


	render_texture_clip_ex(
		cmds,
		tex,
		src_rect.x, src_rect.y, src_rect.w, src_rect.h,
		dst_grid_rect,
		color,
		rotation,
		flip_x,
		flip_y,
	)
}


grid_render_rectangle_lines :: proc(
	cmds : ^[dynamic]Cmd,
	rectangle : shape.Rectangle,
	grid_unit_size : f32,
	thick : f32,
	color : [4]u8,
)
{
	scaled_rectangle := rectangle
	scaled_rectangle.x *= grid_unit_size
	scaled_rectangle.y *= grid_unit_size
	scaled_rectangle.w *= grid_unit_size
	scaled_rectangle.h *= grid_unit_size

	render_rectangle_lines(cmds, scaled_rectangle.x, scaled_rectangle.y, scaled_rectangle.w, scaled_rectangle.h, thick, color.r, color.g, color.b, color.a)

}