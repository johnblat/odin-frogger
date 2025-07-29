package game

import rl "vendor:raylib"
import "./rlgrid"

global_sprite_sheet_cell_size : f32 = 16
bytes_image_data_sprite_sheet_bytes := #load("../assets/frogger_sprite_sheet_modified.png")
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
	Otter,
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
	Empty,         
}


global_sprite_sheet_clips := [Sprite_Clip_Name]rl.Rectangle {
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
	.Otter                        = {6, 7, 1, 1},
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
	.Empty                        = {0, 0, 0, 0},
}

draw_sprite_sheet_clip_on_grid :: proc(sprite_clip: Sprite_Clip_Name, dst_rectangle: rl.Rectangle, dst_grid_cell_size, rotation: f32 )
{
	rectangle_clip := global_sprite_sheet_clips[sprite_clip]
	rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, rectangle_clip, global_sprite_sheet_cell_size, dst_rectangle, dst_grid_cell_size, rotation)
}
