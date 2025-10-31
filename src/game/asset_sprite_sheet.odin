package game

import "../rlgrid"
import shape "../shape"

global_sprite_sheet_cell_size : f32 = 16
// bytes_image_data_sprite_sheet_bytes := #load("../assets/frogger_sprite_sheet_modified.png")
// bytes_image_data_sprite_sheet_bytes := #load("../assets/frogger_sprite_sheet_colton.png")



Sprite_Clip_Name ::  enum {
	Truck,
	Racecar,
	Purple_Car,
	Bulldozer,
	Taxi,
	Long_Log,
	Medium_Log,
	Short_Log,
	Fly,
	Happy_Frog_Closed_Mouth,
	Happy_Frog_Open_Mouth,
	Frogger_Frame_0,
	Frogger_Frame_1,
	Frogger_Frame_2,
	Lily_Frame_0,
	Lily_Frame_1,
	Lily_Frame_2,
	Turtle_Frame_0,
	Turtle_Frame_1,
	Turtle_Frame_2,
	Turtle_Frame_3,
	Turtle_Frame_4,
	Turtle_Frame_5,
	Alligator_Mouth_Closed,
	Alligator_Mouth_Open,
	Snake_Frame_0,
	Snake_Frame_1,
	Snake_Frame_2,
	Otter_Peek,
	Otter_Attacking,
	Score_200,
	Score_100,
	Frogger_Dying_Hit_Frame_0,
	Frogger_Dying_Hit_Frame_1,
	Frogger_Dying_Hit_Frame_2,
	Frogger_Dying_Ripple_Frame_0,
	Frogger_Dying_Ripple_Frame_1,
	Frogger_Dying_Ripple_Frame_2,
	Skull_And_Crossbones,
	Crocodile_Head_Peek,
	Crocodile_Head_Attack,
	Empty,         
}


global_sprite_sheet_clips := [Sprite_Clip_Name]shape.Rectangle {
	.Truck                        = {5, 0, 2, 1},	
	.Racecar                      = {8, 0, 1, 1},
	.Purple_Car                   = {7, 0, 1, 1},
	.Bulldozer                    = {4, 0, 1, 1},
	.Taxi                         = {3, 0, 1, 1},
	.Long_Log                     = {3, 2, 6, 1},
	.Medium_Log                   = {4, 3, 4, 1},
	.Short_Log                    = {6, 8, 3, 1},
	.Fly                          = {2, 6, 1, 1},
	.Happy_Frog_Closed_Mouth      = {3, 6, 1, 1},
	.Happy_Frog_Open_Mouth        = {4, 6, 1, 1},
	.Frogger_Frame_0              = {2, 0, 1, 1},
	.Frogger_Frame_1              = {0, 0, 1, 1},
	.Frogger_Frame_2              = {1, 0, 1, 1},
	.Lily_Frame_0                 = {2, 1, 1, 1},
	.Lily_Frame_1                 = {0, 1, 1, 1},
	.Lily_Frame_2                 = {1, 1, 1, 1},
	.Turtle_Frame_0               = {0, 5, 1, 1},
	.Turtle_Frame_1               = {1, 5, 1, 1},
	.Turtle_Frame_2               = {2, 5, 1, 1},
	.Turtle_Frame_3               = {3, 5, 1, 1},
	.Turtle_Frame_4               = {4, 5, 1, 1},
	.Turtle_Frame_5               = {5, 5, 1, 1},
	.Alligator_Mouth_Open         = {0, 7, 3, 1},
	.Alligator_Mouth_Closed       = {3, 7, 3, 1},
	.Snake_Frame_0                = {0, 8, 2, 1},
	.Snake_Frame_1                = {2, 8, 2, 1},
	.Snake_Frame_2                = {4, 8, 2, 1},
	.Otter_Peek                   = {6, 7, 1, 1},
	.Otter_Attacking              = {7, 7, 1, 1},
	.Score_200                    = {1, 6, 1, 1},
	.Score_100                    = {0, 6, 1, 1},
	.Frogger_Dying_Hit_Frame_0    = {0, 4, 1, 1},
	.Frogger_Dying_Hit_Frame_1    = {1, 4, 1, 1},
	.Frogger_Dying_Hit_Frame_2    = {2, 4, 1, 1},
	.Frogger_Dying_Ripple_Frame_0 = {1, 3, 1, 1},
	.Frogger_Dying_Ripple_Frame_1 = {2, 3, 1, 1},
	.Frogger_Dying_Ripple_Frame_2 = {3, 3, 1, 1},
	.Skull_And_Crossbones         = {0, 3, 1, 1},
	.Crocodile_Head_Peek          = {5, 6, 1, 1},
	.Crocodile_Head_Attack        = {6, 6, 1, 1},
	.Empty                        = {0, 0, 0, 0},
}


draw_sprite_sheet_clip_on_grid :: proc(sprite_clip: Sprite_Clip_Name, dst_rectangle: shape.Rectangle, grid_unit_size, rotation: f32, flip_x : bool = false, flip_y : bool = false )
{
	rectangle_clip := global_sprite_sheet_clips[sprite_clip]
	theme := saved_themes[g_state.active_theme]
	tex_id := theme.sprite_sheet_tex_id
	src_clip_rect := rectangle_clip
	src_clip_rect.x *= global_sprite_sheet_cell_size
	src_clip_rect.y *= global_sprite_sheet_cell_size
	src_clip_rect.w *= global_sprite_sheet_cell_size
	src_clip_rect.h *= global_sprite_sheet_cell_size

	grid_render_texture_clip(
		cmds = &g_state.render_cmds,
		tex = g_state.textures[tex_id],
		src_rect = src_clip_rect,
		dst_rect = dst_rectangle,
		src_grid_unit_size = global_sprite_sheet_cell_size,
		dst_grid_unit_size = grid_unit_size,
		color = { 255, 255, 255, 255 },
		rotation = rotation,
		flip_x = flip_x, flip_y = flip_y
	)
	// rlgrid.draw_grid_texture_clip_on_grid(g_state.textures[.Sprite_Sheet], rectangle_clip, global_sprite_sheet_cell_size, dst_rectangle, grid_unit_size, rotation, flip_x, flip_y)
}


draw_sprite_sheet_clip_on_game_texture_grid :: proc(
	sprite_clip: Sprite_Clip_Name, 
	pos: [2]f32, 
	rotation: f32 = 0.0,  
	scale_x: f32 = 1.0, scale_y: f32 = 1.0, 
	flip_x : bool = false, flip_y : bool = false 
)
{
	rectangle_clip := global_sprite_sheet_clips[sprite_clip]
	dst_rectangle := shape.Rectangle{pos.x, pos.y, rectangle_clip.w * scale_x, rectangle_clip.h * scale_y}
	src_rect := shape.Rectangle { 
		rectangle_clip.x * global_sprite_sheet_cell_size,
		rectangle_clip.y * global_sprite_sheet_cell_size,
		rectangle_clip.w * global_sprite_sheet_cell_size,
		rectangle_clip.h * global_sprite_sheet_cell_size,
	}
	theme := saved_themes[g_state.active_theme]
	tex_id := theme.sprite_sheet_tex_id
	grid_render_texture_clip(
		cmds = &g_state.render_cmds,
		tex = g_state.textures[tex_id],
		src_rect = src_rect,
		dst_rect = dst_rectangle,
		src_grid_unit_size = global_sprite_sheet_cell_size,
		dst_grid_unit_size = global_game_texture_grid_cell_size,
		color = {255, 255, 255, 255},
		rotation = rotation,
		flip_x = flip_x, flip_y = flip_y
	)
	// rlgrid.draw_grid_texture_clip_on_grid(g_state.textures[.Sprite_Sheet], rectangle_clip, global_sprite_sheet_cell_size, dst_rectangle, global_game_texture_grid_cell_size, rotation, flip_x, flip_y)
}


draw_sprite_sheet_clip_on_game_texture_grid_from_animation_player :: proc
(
	animation_player: Animation_Player,
	pos: [2]f32,
	rotation: f32 = 0.0,
	scale_x: f32 = 1.0, scale_y : f32 = 1.0,
	flip_x : bool = false, flip_y : bool = false,
)
{
	clip_name := animation_get_frame_sprite_clip_id(animation_player.timer.t, animation_player.fps, global_sprite_animations[animation_player.animation_name])
	draw_sprite_sheet_clip_on_game_texture_grid(clip_name, pos, rotation, scale_x, scale_y, flip_x, flip_y)
}
