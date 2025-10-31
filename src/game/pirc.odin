package game

// PIRC = Platform Independent Render Commands

import "core:math"
import "core:slice"
import "core:fmt"
import "../shape"





Texture :: struct 
{
	id : Texture_Id,
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


measure_text :: proc(text: string, font: Font, size: f32) -> [2]f32 
{
	scale := size / cast(f32)font.line_height

	width: f32 = 0
	max_width: f32 = 0
	height: f32 = cast(f32)font.line_height * scale

	for c in text 
	{
		if c == '\n' 
		{
			if width > max_width 
			{
				max_width = width
			}
			width = 0
			height += cast(f32)font.line_height * scale
			continue
		}

		if c < ' ' || c > '~' 
		{
			continue // skip unsupported characters
		}

		index := cast(int)(c - ' ')
		glyph := font.packed_chars[index]
		width += glyph.xadvance * scale
	}

	if width > max_width 
	{
		max_width = width
	}

	return [2]f32{max_width, height}
}



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
	cmd := Cmd_Text { 
		pos = pos,
		size = size,
		font = font_id,
		color = color,
		text = text,
	}
	append(cmds, cmd)
}


grid_render_text_tprintf :: proc(
	cmds : ^[dynamic]Cmd, 
	pos : [2]f32, 
	font_id : Font_Id, 
	size : f32, 
	color : [4]u8, 
	dst_grid_unit_size : f32, 
	fmt_s : string, args : ..any
)
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


grid_render_text_tprintf_ex :: proc(
	cmds : ^[dynamic]Cmd, 
	pos : [2]f32, 
	font_id : Font_Id, 
	size : f32, 
	color : [4]u8, 
	dst_grid_unit_size : f32, 
	h_align : H_Alignment,
	v_align : V_Alignment,
	fmt_s : string, args : ..any
)
{
	// TODO: handle alignment
	text := fmt.tprintf(fmt_s, ..args)
	font_info := g_state.font_infos[font_id]
	text_dimensions := measure_text(text, font_info, size)

	aligned_pos := pos
	
	switch h_align
	{
		case .Center:
		{
			aligned_pos.x -= text_dimensions.x/2
		}
		case .Left: {}
		case .Right:
		{
			aligned_pos.x -= text_dimensions.x
		}
	}

	switch v_align
	{
		case .Center:
		{
			aligned_pos.y -= text_dimensions.y/2
		}
		case .Top: {}
		case .Bottom:
		{
			aligned_pos.y -= text_dimensions.y
		}
	}

	grid_render_text_tprintf(
		cmds,
		aligned_pos,
		font_id,
		size,
		color,
		dst_grid_unit_size,
		fmt_s, ..args
	)
}


grid_render_text_tprintf_ex_with_background :: proc(
	cmds : ^[dynamic]Cmd, 
	pos : [2]f32, 
	font_id : Font_Id, 
	size : f32, 
	text_color : [4]u8, 
	bg_color : [4]u8,
	dst_grid_unit_size : f32, 
	h_align : H_Alignment,
	v_align : V_Alignment,
	fmt_s : string, args : ..any
)
{
	// TODO make rectangle size the dimensions of the text
	text := fmt.tprintf(fmt_s, ..args)
	text_dimensions := measure_text(text, g_state.font_infos[font_id], size)
	rectangle := shape.Rectangle { pos.x, pos.y, text_dimensions.x, size}
	rectangle.w += 0.8

	grid_render_rectangle_fill_ex(
		cmds,
		rectangle,
		dst_grid_unit_size,
		bg_color,
		h_align,
		v_align
	)

	grid_render_text_tprintf_ex(
		cmds, 
		pos,
		font_id,
		size,
		text_color,
		dst_grid_unit_size,
		h_align,
		v_align,
		fmt_s, ..args
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


grid_render_rectangle_fill_ex :: proc(
	cmds : ^[dynamic]Cmd,
	rectangle : shape.Rectangle,
	grid_unit_size : f32,
	color : [4]u8,
	h_align : H_Alignment = .Left,
	v_align : V_Alignment = .Top,
)
{
	aligned_rectangle := rectangle
	#partial switch h_align
	{
		case .Center : {aligned_rectangle.x -= rectangle.w/2}
		case .Right  : {aligned_rectangle.x -= rectangle.w}
	}
	#partial switch v_align
	{
		case .Center : {aligned_rectangle.y -= rectangle.h/2}
		case .Bottom : {aligned_rectangle.y -= rectangle.h}
	}
	grid_scaled_rectangle := aligned_rectangle
	grid_scaled_rectangle.x *= grid_unit_size
	grid_scaled_rectangle.y *= grid_unit_size
	grid_scaled_rectangle.w *= grid_unit_size
	grid_scaled_rectangle.h *= grid_unit_size

	render_rectangle_fill(
		cmds, 
		grid_scaled_rectangle.x, 
		grid_scaled_rectangle.y,
		grid_scaled_rectangle.w,
		grid_scaled_rectangle.h,
		color.r, color.g, color.b, color.a
	)
}


