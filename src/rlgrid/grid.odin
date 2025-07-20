package rlgrid

import rl "vendor:raylib"

get_rectangle_on_grid :: proc(rectangle: rl.Rectangle, cell_size: f32) -> rl.Rectangle
{
	ret := rl.Rectangle {
		rectangle.x      * cell_size,
		rectangle.y      * cell_size,
		rectangle.width  * cell_size,
		rectangle.height * cell_size,
	}

	return ret
}


draw_rectangle_on_grid :: proc(rectangle: rl.Rectangle, color: rl.Color, cell_size: f32)
{
	render_rectangle := get_rectangle_on_grid(rectangle, cell_size)
	rl.DrawRectangleRec(render_rectangle, color)
}


draw_rectangle_lines_on_grid :: proc(rectangle: rl.Rectangle, line_thick: f32, color: rl.Color, cell_size: f32)
{
	render_rectangle := get_rectangle_on_grid(rectangle, cell_size)
	rl.DrawRectangleLinesEx(render_rectangle, line_thick, color)
}


get_grid_cell_rectangle :: proc(grid_pos: [2]f32, cell_size: f32) -> rl.Rectangle
{
	ret := rl.Rectangle{
		grid_pos.x * cell_size,
		grid_pos.y * cell_size,
		cell_size,
		cell_size
	}

	return ret
}


draw_sprite_sheet_clip_on_grid :: proc(sprite_sheet: rl.Texture2D, src_grid_pos, dst_grid_pos: [2]f32, src_cell_size, dst_cell_size, rotation: f32) 
{
	src_rect := get_grid_cell_rectangle(src_grid_pos, src_cell_size)
	dst_rect := get_grid_cell_rectangle(dst_grid_pos, dst_cell_size)
	dst_midpoint := [2]f32{dst_rect.width / 2, dst_rect.height / 2}
	dst_rect.x += dst_midpoint.x
	dst_rect.y += dst_midpoint.y
	rl.DrawTexturePro(sprite_sheet, src_rect, dst_rect, [2]f32{dst_midpoint.x, dst_midpoint.y}, rotation, rl.WHITE)
}


draw_sprite_sheet_rectangle_clip_on_grid :: proc(sprite_sheet: rl.Texture2D, src_grid, dst_grid: rl.Rectangle, src_cell_size, dst_cell_size, rotation: f32) 
{
	src_rect := get_rectangle_on_grid(src_grid, src_cell_size)
	dst_rect := get_rectangle_on_grid(dst_grid, dst_cell_size)
	rotation_origin := [2]f32{dst_rect.width / 2, dst_rect.height / 2}
	dst_rect.x += rotation_origin.x
	dst_rect.y += rotation_origin.y

	// rl.DrawCircleV(rotation_origin, 5, rl.RED)
	rl.DrawTexturePro(sprite_sheet, src_rect, dst_rect, rotation_origin, rotation, rl.WHITE)
	// rl.DrawCircleV([2]f32{dst_rect.x, dst_rect.y}, 5, rl.RED)
	// rl.DrawLineV(rotation_origin, [2]f32{dst_rect.x, dst_rect.y}, rl.WHITE)

}

draw_text_on_grid :: proc(font: rl.Font, text: cstring, pos: [2]f32, size: f32, spacing: f32, tint: rl.Color, grid_cell_size: f32)
{
	dst_pos     := [2]f32{pos.x * grid_cell_size, pos.y * grid_cell_size}
	dst_spacing := spacing * grid_cell_size
	dst_size    := size * grid_cell_size
	rl.DrawTextEx(font, text, dst_pos, dst_size, dst_spacing, tint)
}


draw_text_on_grid_right_justified :: proc(font: rl.Font, text: cstring, pos: [2]f32, size, spacing: f32, tint: rl.Color, grid_cell_size: f32)
{
	text_dimensions := rl.MeasureTextEx(font, text, size, spacing)
	dst_pos := [2]f32 {
		pos.x - f32(text_dimensions.x),
		pos.y,
	}
	draw_text_on_grid(font, text, dst_pos, size, spacing, tint, grid_cell_size)
}

draw_text_on_grid_centered :: proc(font: rl.Font, text: cstring, pos: [2]f32, size, spacing: f32, tint: rl.Color, grid_cell_size: f32)
{
	text_dimensions := rl.MeasureTextEx(font, text, size, spacing)
	dst_pos := [2]f32 {
		pos.x - f32(text_dimensions.x)/2,
		pos.y,
	}
	draw_text_on_grid(font, text, dst_pos, size, spacing, tint, grid_cell_size)
}