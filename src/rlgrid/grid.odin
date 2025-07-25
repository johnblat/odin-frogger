package rlgrid

import rl "vendor:raylib"
import "core:math"

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


/** draw_grid_texture_clip_on_grid 
 * 
 * terms:
 * - clip: A rectangular subsection of a larger texture. For example, a sprite sheet has many sprites in it, and you just want one, so you take a clip from it
 * - render target: Whatever canvas you are drawing on.
 * - texture: an image loaded onto GPU
 *
 * inputs:
 * - tex: Source Texture to take a clip out of
 * - src_rectangle: The clip dimensions in grid coordinates of the source texture's grid
 * - src_grid_cell_size: The cell size of the source texture's grid. For example, maybe the sprites each take up 16 x 16 pixels. In this case, src_grid_cell_size will be 16
 * - dst_rectangle: The destination that the clip should be drawn at on wherever the render target is pointing to. If the dst_rectangle is smaller than the src_rectangle, the sprite will be shrunk. If the dst_rectangle is larger than the src_rectangle, then it will be stretched larger. 
 * - dst_grid_cell_size: The cell size of the render target's grid. So if we are rendering to a grid where each cell is 32 x 32 pixels, the value will be 32
 * - rotation: the rotation in degrees to rotate the sprite on the render target
 * 
 * **/
draw_grid_texture_clip_on_grid :: proc(tex: rl.Texture2D, src_rectangle: rl.Rectangle, src_grid_cell_size: f32, dst_rectangle: rl.Rectangle, dst_grid_cell_size, rotation: f32) 
{
	src_rect := get_rectangle_on_grid(src_rectangle, src_grid_cell_size)
	dst_rect := get_rectangle_on_grid(dst_rectangle, dst_grid_cell_size)
	rotation_origin := [2]f32{dst_rect.width / 2, dst_rect.height / 2}
	dst_rect.x += rotation_origin.x
	dst_rect.y += rotation_origin.y
	// dst_rect.x = math.floor(dst_rect.x)
	// dst_rect.y = math.floor(dst_rect.y)

	// rl.DrawCircleV(rotation_origin, 5, rl.RED)
	rl.DrawTexturePro(tex, src_rect, dst_rect, rotation_origin, rotation, rl.WHITE)
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