package game

import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strings"

import rlgrid "./rlgrid"

// bytes_image_data_background         := #load("../assets/frogger_background_colton.png")
bytes_image_data_background         := #load("../assets/frogger_background_modified.png")
bytes_font_data                     := #load("../assets/joystix monospace.otf")
bytes_aa_pixel_filter_shader        := #load("./pixel_filter.fs")


global_filename_window_save_data := "window_save_data.frog"

global_grid_cell_size                : f32 : 64
global_number_grid_cells_axis_x : f32 : 14
global_number_grid_cells_axis_y : f32 : 16
global_game_view_pixels_width   : f32 : global_grid_cell_size * global_number_grid_cells_axis_x
global_game_view_pixels_height  : f32 : global_grid_cell_size * global_number_grid_cells_axis_y


Window_Save_Data :: struct
{
	x, y, width, height: i32
}


Sprite_Data :: union {
	Sprite_Sheet_Clip,
	Regular_Turtle_Animation,
	Diving_Turtle_Animation,
}

Regular_Turtle_Animation :: struct {}
Diving_Turtle_Animation :: struct {
	timer_id: int,
}



Collision_Behavior :: enum {
	Move_Frogger,
	Kill_Frogger,
}

Entity :: struct
{
	rectangle : rl.Rectangle,
	speed     : f32,
	warp_boundary_extension : f32,
	sprite_data: Sprite_Data,
	collision_behavior: Collision_Behavior,
}


Game_Memory :: struct
{	
	// VIEW
	game_render_target: rl.RenderTexture,

	// Spritesheets
	texture_sprite_sheet : rl.Texture2D,
	texture_background   : rl.Texture2D,

	// Font
	font :rl.Font,

	// DEBUG
	dbg_show_grid : bool,
	dbg_is_frogger_unkillable : bool,
	dbg_show_entity_bounding_rectangles : bool,

	// GAME

	level_current : int,

	// frogger
	frogger_pos       : [2]f32,
	frogger_move_lerp_timer     : Timer,
	frogger_move_lerp_start_pos : [2]f32,
	frogger_move_lerp_end_pos   : [2]f32,

	frogger_sprite_rotation: f32,
	frogger_is_dying_timer : Animation_Timer,

	is_lily_on_frogger : bool,

	// win
	is_frog_on_lilypads :[5]bool,
	level_end_timer :Timer,

	// score
	score :int,
	score_frogger_max_y_tracker : f32,

	timer_is_active_score_100: Timer,
	timer_is_active_score_200: Timer,

	pos_score_100: [2]f32,
	pos_score_200: [2]f32,


	// entities
	// entities_by_level :[][]Entity,

	// entities :[]Entity,

	pause : bool,

	lives: int,
	counter_cycle: int,
	counter_level: int,

	// shader
	shader_pixel_filter: rl.Shader
}


gmem: ^Game_Memory


lilypads := [5]rl.Rectangle{
	{.5,   2, 1, 1},
	{3.5,  2, 1, 1},
	{6.5,  2, 1, 1},
	{9.5,  2, 1, 1},
	{12.5, 2, 1, 1},
}


@(export)
game_memory_size :: proc() -> int
{
	return size_of(gmem)
}


@(export)
game_memory_ptr :: proc() -> rawptr
{
	return gmem
}


@(export)
game_hot_reload :: proc(mem: rawptr)
{
	gmem = (^Game_Memory)(mem)
}


@(export)
game_is_build_requested :: proc() -> bool
{
	yes := rl.IsKeyPressed(.F5)
	if yes
	{
		return true
	}
	return false
}


@(export)
game_should_run :: proc() -> bool
{
	no := rl.WindowShouldClose()
	if no
	{
		return false
	}
	return true
}


@(export)
game_free_memory :: proc()
{
	free(gmem)
	rl.UnloadRenderTexture(gmem.game_render_target)
}




@(export)
game_init_platform :: proc()
{
	default_window_width : i32 = 224 * 4
	default_window_height : i32 = 256 * 4

	window_width : i32 = default_window_width
	window_height : i32 = default_window_height
	window_pos_x : i32 = 0
	window_pos_y : i32 = 50

	window_save_data := Window_Save_Data{}

	bytes_window_save_data, err := os2.read_entire_file_from_path(global_filename_window_save_data, context.temp_allocator)

	if err != nil
	{
		fmt.printfln("Error reading from window save data file: %v", err)
	}
	else
	{
		mem.copy(&window_save_data, &bytes_window_save_data[0], size_of(window_save_data))

		window_width = window_save_data.width
		window_height = window_save_data.height
		window_pos_x = window_save_data.x
		window_pos_y = window_save_data.y
	}

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(window_width, window_height, "Frogger [For Educational Purposes Only]")
	rl.SetWindowPosition(window_pos_x, window_pos_y)

	after_set_pos_monitor_id     := rl.GetCurrentMonitor()
	after_set_pos_monitor_pos    := rl.GetMonitorPosition(after_set_pos_monitor_id)
	after_set_pos_monitor_width  := rl.GetMonitorWidth(after_set_pos_monitor_id)
	after_set_pos_monitor_height := rl.GetMonitorHeight(after_set_pos_monitor_id)

	is_window_out_of_monitor_bounds := f32(window_pos_x) < after_set_pos_monitor_pos.x ||
		f32(window_pos_y) < after_set_pos_monitor_pos.y ||
		window_pos_x > after_set_pos_monitor_width ||
		window_pos_y > after_set_pos_monitor_height

	if is_window_out_of_monitor_bounds
	{
		reset_window_pos_x := i32(after_set_pos_monitor_pos.x)
		reset_window_pos_y := i32(after_set_pos_monitor_pos.y) + 40
		reset_window_width := default_window_width
		reset_window_height := default_window_height

		rl.SetWindowPosition(reset_window_pos_x, reset_window_pos_y)
		rl.SetWindowSize(reset_window_width, reset_window_height)
	}
	
	rl.SetTargetFPS(60)
}




is_frogs_on_lilypad := [5]bool{true, true, true, true, false}


entities_by_level := [?][]Entity {
	entities_level_1[:],
	entities_level_2[:],
}

entities_level_1 := [?]Entity {
	{ rectangle = {1,   9, 2, 1},  speed = -1.5  ,warp_boundary_extension = 0,   sprite_data = .Truck,                                  collision_behavior = .Kill_Frogger},
	{ rectangle = {6.5, 9, 2, 1},  speed = -1.5  ,warp_boundary_extension = 0,   sprite_data = .Truck,                                  collision_behavior = .Kill_Frogger},
	{ rectangle = {1,  10, 1, 1},  speed =  1  ,warp_boundary_extension = 0,   sprite_data = .Racecar,                                collision_behavior = .Kill_Frogger},
	{ rectangle = {10, 11, 1, 1},  speed = -0.8  ,warp_boundary_extension = 0,   sprite_data = .Purple_Car,                             collision_behavior = .Kill_Frogger},
	{ rectangle = {6,  11, 1, 1},  speed = -0.8  ,warp_boundary_extension = 0,   sprite_data = .Purple_Car,                             collision_behavior = .Kill_Frogger},
	{ rectangle = {2,  11, 1, 1},  speed = -0.8  ,warp_boundary_extension = 0,   sprite_data = .Purple_Car,                             collision_behavior = .Kill_Frogger},
	{ rectangle = {5,  12, 1, 1},  speed =  0.6  ,warp_boundary_extension = 0,   sprite_data = .Bulldozer,                              collision_behavior = .Kill_Frogger},
	{ rectangle = {9,  12, 1, 1},  speed =  0.6  ,warp_boundary_extension = 0,   sprite_data = .Bulldozer,                              collision_behavior = .Kill_Frogger},
	{ rectangle = {13, 12, 1, 1},  speed =  0.6  ,warp_boundary_extension = 0,   sprite_data = .Bulldozer,                              collision_behavior = .Kill_Frogger},
	{ rectangle = {10, 13, 1, 1},  speed = -0.6  ,warp_boundary_extension = 0,   sprite_data = .Taxi,                                   collision_behavior = .Kill_Frogger},
	{ rectangle = {6,  13, 1, 1},  speed = -0.6  ,warp_boundary_extension = 0,   sprite_data = .Taxi,                                   collision_behavior = .Kill_Frogger},
	{ rectangle = {2,  13, 1, 1},  speed = -0.6  ,warp_boundary_extension = 0,   sprite_data = .Taxi,                                   collision_behavior = .Kill_Frogger},
	{ rectangle = {0,  3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {6,  3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {12, 3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {18, 3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {0,  5, 6, 1},   speed = 3, warp_boundary_extension = 4,   sprite_data = .Long_Log,                               collision_behavior = .Move_Frogger},	
	{ rectangle = {8,  5, 6, 1},   speed = 3, warp_boundary_extension = 4,   sprite_data = .Long_Log,                               collision_behavior = .Move_Frogger},
	{ rectangle = {16, 5, 6, 1},   speed = 3, warp_boundary_extension = 4,   sprite_data = .Long_Log,                               collision_behavior = .Move_Frogger},
	{ rectangle = {0,  6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {5,  6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {10, 6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {15, 6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {2,  4, 1, 1},   speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {3,  4, 1, 1},   speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {6,  4, 1, 1},   speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {7,  4, 1, 1},   speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {10, 4, 1, 1},   speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {11, 4, 1, 1},   speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {0,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {1,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {2,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {4,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {5,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {6,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {8,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {9,  7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {10, 7, 1, 1},   speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {15.5, 4, 1, 1}, speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Diving_Turtle_Animation{ timer_id = 0 }, collision_behavior = .Move_Frogger }, 
	{ rectangle = {16.5, 4, 1, 1}, speed = -1.5,  warp_boundary_extension = 2.5, sprite_data = Diving_Turtle_Animation{ timer_id = 0 }, collision_behavior = .Move_Frogger },
	{ rectangle = {12,   7, 1, 1}, speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Diving_Turtle_Animation{ timer_id = 1 }, collision_behavior = .Move_Frogger }, 
	{ rectangle = {13,   7, 1, 1}, speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Diving_Turtle_Animation{ timer_id = 1 }, collision_behavior = .Move_Frogger }, 
	{ rectangle = {14,   7, 1, 1}, speed = -1.5,  warp_boundary_extension = 1  , sprite_data = Diving_Turtle_Animation{ timer_id = 1 }, collision_behavior = .Move_Frogger }
}

entities_level_2 := [?]Entity {
	{ rectangle = {1,   9, 2, 1},  speed = -1.5,warp_boundary_extension = 0,   sprite_data = .Truck,                                  collision_behavior = .Kill_Frogger},
	{ rectangle = {6.5, 9, 2, 1},  speed = -1.5,warp_boundary_extension = 0,   sprite_data = .Truck,                                  collision_behavior = .Kill_Frogger},
	{ rectangle = {1,  10, 1, 1},  speed =  2  ,warp_boundary_extension = 0,   sprite_data = .Racecar,                                collision_behavior = .Kill_Frogger},
	{ rectangle = {5,  10, 1, 1},  speed =  2  ,warp_boundary_extension = 0,   sprite_data = .Racecar,                                collision_behavior = .Kill_Frogger},
	{ rectangle = {9,  10, 1, 1},  speed =  2  ,warp_boundary_extension = 0,   sprite_data = .Racecar,                                collision_behavior = .Kill_Frogger},
	{ rectangle = {10, 11, 1, 1},  speed = -2  ,warp_boundary_extension = 0,   sprite_data = .Purple_Car,                             collision_behavior = .Kill_Frogger},
	{ rectangle = {6,  11, 1, 1},  speed = -2  ,warp_boundary_extension = 0,   sprite_data = .Purple_Car,                             collision_behavior = .Kill_Frogger},
	{ rectangle = {2,  11, 1, 1},  speed = -2  ,warp_boundary_extension = 0,   sprite_data = .Purple_Car,                             collision_behavior = .Kill_Frogger},
	{ rectangle = {5,  12, 1, 1},  speed =  2  ,warp_boundary_extension = 0,   sprite_data = .Bulldozer,                              collision_behavior = .Kill_Frogger},
	{ rectangle = {9,  12, 1, 1},  speed =  2  ,warp_boundary_extension = 0,   sprite_data = .Bulldozer,                              collision_behavior = .Kill_Frogger},
	{ rectangle = {13, 12, 1, 1},  speed =  2  ,warp_boundary_extension = 0,   sprite_data = .Bulldozer,                              collision_behavior = .Kill_Frogger},
	{ rectangle = {10, 13, 1, 1},  speed = -1  ,warp_boundary_extension = 0,   sprite_data = .Taxi,                                   collision_behavior = .Kill_Frogger},
	{ rectangle = {6,  13, 1, 1},  speed = -1  ,warp_boundary_extension = 0,   sprite_data = .Taxi,                                   collision_behavior = .Kill_Frogger},
	{ rectangle = {2,  13, 1, 1},  speed = -1  ,warp_boundary_extension = 0,   sprite_data = .Taxi,                                   collision_behavior = .Kill_Frogger},
	{ rectangle = {0,  3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {6,  3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {12, 3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {18, 3, 4, 1},   speed = 1.2, warp_boundary_extension = 7,   sprite_data = .Medium_Log,                             collision_behavior = .Move_Frogger},
	{ rectangle = {0,  5, 6, 1},   speed = 2.2, warp_boundary_extension = 4,   sprite_data = .Long_Log,                               collision_behavior = .Move_Frogger},	
	{ rectangle = {8,  5, 6, 1},   speed = 2.2, warp_boundary_extension = 4,   sprite_data = .Long_Log,                               collision_behavior = .Move_Frogger},
	{ rectangle = {16, 5, 6, 1},   speed = 2.2, warp_boundary_extension = 4,   sprite_data = .Long_Log,                               collision_behavior = .Move_Frogger},
	{ rectangle = {0,  6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {5,  6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {10, 6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {15, 6, 3, 1},   speed = 0.8, warp_boundary_extension = 4,   sprite_data = .Short_Log,                              collision_behavior = .Move_Frogger},
	{ rectangle = {2,  4, 1, 1},   speed = -2,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {3,  4, 1, 1},   speed = -2,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {6,  4, 1, 1},   speed = -2,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {7,  4, 1, 1},   speed = -2,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {10, 4, 1, 1},   speed = -2,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {11, 4, 1, 1},   speed = -2,  warp_boundary_extension = 2.5, sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {0,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {1,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {2,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {4,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {5,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {6,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {8,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {9,  7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger}, 
	{ rectangle = {10, 7, 1, 1},   speed = -2,  warp_boundary_extension = 1  , sprite_data = Regular_Turtle_Animation{},              collision_behavior = .Move_Frogger},
	{ rectangle = {15.5, 4, 1, 1}, speed = -2,  warp_boundary_extension = 2.5, sprite_data = Diving_Turtle_Animation{ timer_id = 0 }, collision_behavior = .Move_Frogger }, 
	{ rectangle = {16.5, 4, 1, 1}, speed = -2,  warp_boundary_extension = 2.5, sprite_data = Diving_Turtle_Animation{ timer_id = 0 }, collision_behavior = .Move_Frogger },
	{ rectangle = {12,   7, 1, 1}, speed = -2,  warp_boundary_extension = 1  , sprite_data = Diving_Turtle_Animation{ timer_id = 1 }, collision_behavior = .Move_Frogger }, 
	{ rectangle = {13,   7, 1, 1}, speed = -2,  warp_boundary_extension = 1  , sprite_data = Diving_Turtle_Animation{ timer_id = 1 }, collision_behavior = .Move_Frogger }, 
	{ rectangle = {14,   7, 1, 1}, speed = -2,  warp_boundary_extension = 1  , sprite_data = Diving_Turtle_Animation{ timer_id = 1 }, collision_behavior = .Move_Frogger }
}

regular_turtles_anim_fps : f32 = 3
regular_turtles_anim_timer : f32 = 0

diving_turtles_anim_fps : f32 = regular_turtles_anim_fps

diving_turtles_anim_timers := [?]f32 {0, 1}


frogger_anim_timer := Timer {
	amount = 0.25,
	duration = 0.25,
}

frogger_move_lerp_duration : f32 = 0.1




fly_lilypad_indices := [?]int{3, 1, 3, 1, 0, 2, 4, 3, 1, 0, 4, 2, 4, 3, 0, 0, 2}
fly_lilypad_index : int  = 0 // index into array above, not the lilypad
fly_timer := Timer{
	amount = 0,
	duration = 4.0,
}
fly_is_active : bool     = false


global_sprite_clip_score_100 := rl.Rectangle {0, 6, 1, 1}
global_sprite_clip_score_200 := rl.Rectangle {1, 6, 1, 1}


Direction :: enum {
	Up, Down, Left, Right
}

map_direction_rotation := [Direction]f32 {
	.Up = 0,
	.Down = 180,
	.Left = 270,
	.Right = 90
}


lily_is_active : bool = false
lily_sprite_sheet_clip := rl.Rectangle {2, 1, 1, 1}
lily_relative_log_pos_x : f32 = 0
lily_width : f32 = 1
lily_height : f32 = 1
lily_is_on_frogger := false

lily_wait_timer := Timer {
	amount   = 0,
	duration = 1,
}

lily_direction : Direction = .Right

lily_lerp_timer := Timer {
	amount = 0.2,
	duration = 0.2,
}
lily_lerp_relative_log_start_x : f32 = 0
lily_lerp_relative_log_end_x   : f32 = 0 

lily_logs_to_spawn_on := [?]int{18, 1, 3}
lily_log_to_spawn_on_index : int = 0 // index into above array


// TODO(jblat): Make it so duration is calculated every frame and not on setup
frogger_is_dying_animation_fps : f32 = 12
frogger_is_dying_splat_animation_frames := [?]rl.Rectangle{
	{0, 4, 1, 1}, {1, 4, 1, 1}, {2, 4, 1, 1}, {1, 4, 1, 1}, 
	{0, 4, 1, 1}, {1, 4, 1, 1}, {2, 4, 1, 1}, {1, 4, 1, 1}, 
	{0, 4, 1, 1}, {1, 4, 1, 1}, {2, 4, 1, 1}, {1, 4, 1, 1}, 
	{0, 4, 1, 1}, {1, 4, 1, 1}, {2, 4, 1, 1}, {1, 4, 1, 1}, 
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{3, 4, 1, 1},
}
frogger_is_dying_ripple_animation_frames := [?]rl.Rectangle{
	{1, 3, 1, 1}, {2, 3, 1, 1}, {3, 3, 1, 1},
	{1, 3, 1, 1}, {2, 3, 1, 1}, {3, 3, 1, 1},
	{1, 3, 1, 1}, {2, 3, 1, 1}, {3, 3, 1, 1},
	{1, 3, 1, 1}, {2, 3, 1, 1}, {3, 3, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{0, 3, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}, {3, 4, 1, 1},
	{3, 4, 1, 1},
}

frogger_is_dying_animation_frames : []rl.Rectangle


move_entities_and_wrap :: proc(entities: []Entity, dt: f32)
{
	for &entity in entities
	{
		rectangle := &entity.rectangle
		rectangle_move_amount := entity.speed * dt
		rectangle.x += rectangle_move_amount

		warp_pos_on_left_side_x := -rectangle.width
		should_warp_to_right_side_of_screen := rectangle_move_amount < 0 && rectangle.x < warp_pos_on_left_side_x

		warp_pos_on_right_side_x := global_number_grid_cells_axis_x + entity.warp_boundary_extension
		should_warp_to_left_side_of_screen := rectangle_move_amount > 0 && rectangle.x > warp_pos_on_right_side_x 

		if should_warp_to_right_side_of_screen
		{
			overshoot : f32 = warp_pos_on_left_side_x - rectangle.x 
			rectangle.x = global_number_grid_cells_axis_x + entity.warp_boundary_extension - overshoot
		}
		else if should_warp_to_left_side_of_screen 
		{
			overshoot : f32 = rectangle.x - warp_pos_on_right_side_x
			rectangle.x = -rectangle.width + overshoot
		}
	}
}


move_frogger_with_intersecting_entities :: proc(frogger_pos, frogger_lerp_end_pos: [2]f32, entities: []Entity, dt: f32) -> (moved_pos: [2]f32, moved_lerp_end_pos: [2]f32)
{

	// Note(jblat): this assumes the position refers to something that is 1 x 1 tile rectangle shape
	// also, if for some reason frogger ever collides with multiple entities, he will move multiple times, so.... yeah...
	center_pos := [2]f32{frogger_pos.x + 0.5, frogger_pos.y + 0.5}
	moved_pos = frogger_pos
	moved_lerp_end_pos = frogger_lerp_end_pos

	for entity, i in entities 
	{
		// TODO(jblat): don't do the processing here probably
		if entity.collision_behavior != .Move_Frogger
		{
			continue
		}
		is_center_pos_inside_log_rectangle := rl.CheckCollisionPointRec(center_pos, entity.rectangle)
		should_frogger_move_with_entity := is_center_pos_inside_log_rectangle 
		
		if should_frogger_move_with_entity 
		{
			move_speed : f32 = entity.speed
			move_amount := move_speed * dt

			moved_pos.x += move_amount
			moved_lerp_end_pos.x += move_amount

		}
	}

	return
}


// Note(jblat): This will make sure that if the above entities change,
// They will actually be reset
// @(export)
// game_reset_entities :: proc(mem: ^Game_Memory)
// {
// 	gmem.entities = entities[:]
// }




@(export)
game_init :: proc()
{

	frogger_move_lerp_timer  := Timer {
		amount = frogger_move_lerp_duration,
		duration = frogger_move_lerp_duration,
	}

	frogger_move_lerp_start_pos : [2]f32
	frogger_move_lerp_end_pos   : [2]f32


	gmem = new(Game_Memory)


	string_fs  := strings.string_from_ptr(&bytes_aa_pixel_filter_shader[0], len(bytes_aa_pixel_filter_shader))
	cstring_fs := strings.clone_to_cstring(string_fs, context.temp_allocator)
	gmem.shader_pixel_filter = rl.LoadShaderFromMemory(nil, cstring_fs)
	game_render_target := rl.LoadRenderTexture(i32(global_game_view_pixels_width), i32(global_game_view_pixels_height))
	rl.SetTextureFilter(game_render_target.texture, rl.TextureFilter.BILINEAR)

	gmem.game_render_target = game_render_target

	gmem.dbg_show_grid = false
	gmem.dbg_is_frogger_unkillable = false

	gmem.frogger_pos = [2]f32{7,14}
	gmem.frogger_move_lerp_timer = frogger_move_lerp_timer
	gmem.frogger_move_lerp_start_pos = frogger_move_lerp_start_pos
	gmem.frogger_move_lerp_end_pos = frogger_move_lerp_end_pos

	gmem.is_frog_on_lilypads = is_frogs_on_lilypad

	image_sprite_sheet := rl.LoadImageFromMemory(".png", &bytes_image_data_sprite_sheet_bytes[0], i32(len(bytes_image_data_sprite_sheet_bytes)))
	image_background   := rl.LoadImageFromMemory(".png", &bytes_image_data_background[0], i32(len(bytes_image_data_background)))

	gmem.texture_sprite_sheet = rl.LoadTextureFromImage(image_sprite_sheet)
	gmem.texture_background   = rl.LoadTextureFromImage(image_background)

	gmem.font = rl.LoadFontFromMemory(".otf", &bytes_font_data[0], i32(len(bytes_font_data)), 256, nil, 0)

	gmem.score_frogger_max_y_tracker = gmem.frogger_pos.y - 1

	gmem.level_end_timer = Timer{
		amount = 2.0,
		duration = 2.0,
		loop = false,
	}

	gmem.timer_is_active_score_100 = timer_init(2.0, false)
	gmem.timer_is_active_score_200 = timer_init(2.0, false)

	gmem.frogger_is_dying_timer = Animation_Timer{
		t = 0,
		loop = false,
		playing = false,
	}

	// game_reset_entities(gmem)
}


frogger_reset :: proc(pos: [2]f32)
{
	gmem.frogger_pos = pos
	gmem.score_frogger_max_y_tracker = pos.y - 1
	gmem.is_lily_on_frogger = false
	timer_stop(&gmem.frogger_move_lerp_timer)
}


frogger_start_dying :: proc()
{
	gmem.is_lily_on_frogger = false
	timer_stop(&gmem.frogger_move_lerp_timer)
	animation_timer_start(&gmem.frogger_is_dying_timer)
}



@(export)
game_update :: proc()
{
	entities := entities_by_level[gmem.level_current]
	if rl.IsKeyPressed(.SPACE)
	{
		fmt.printfln("Hey!")
	}
	if rl.IsKeyPressed(.ENTER)
	{
		gmem.pause = !gmem.pause
	}

	if rl.IsKeyPressed(.BACKSPACE)
	{
		gmem.pause = !gmem.pause

	}

	frame_time_uncapped := rl.GetFrameTime()
	frame_time := min(frame_time_uncapped, f32(1.0/60.0))

	frogger_start_pos := [2]f32{7,14}

	frogger_anim_frames := [?]rl.Rectangle{
		{0, 0, 1, 1}, {1, 0, 1, 1}, {0, 0, 1, 1}, {2, 0, 1, 1}
	}

	regular_turtle_anim_frames := [?]rl.Rectangle{
		{0,5,1,1}, {1,5,1,1}, {2,5,1,1}
	}

	diving_turtle_anim_frames := [?]rl.Rectangle{
		{0,5,1,1}, {1,5,1,1}, {2,5,1,1}, {3,5,1,1}, {4,5,1,1}, {5,5,1,1}, {4,5,1,1}, {3,5,1,1}
	}

	diving_turtle_underwater_frame : int = 5


	river := rl.Rectangle{0, 3, 14, 5}
	riverbed := rl.Rectangle{0, 1, 14,2}


	if !gmem.pause 
	{	

		can_frogger_request_move := timer_is_complete(gmem.frogger_move_lerp_timer)  && !animation_timer_is_playing(gmem.frogger_is_dying_timer) && timer_is_complete(gmem.level_end_timer)
		if can_frogger_request_move  
		{
			frogger_move_direction := [2]f32{0,0}
			if rl.IsKeyPressed(.LEFT) 
			{
				frogger_move_direction.x = -1
				gmem.frogger_sprite_rotation  = 270
				timer_start(&frogger_anim_timer)
			}
			else if rl.IsKeyPressed(.RIGHT) 
			{
				frogger_move_direction.x = 1
				gmem.frogger_sprite_rotation = 90
				timer_start(&frogger_anim_timer)
			} 
			else if rl.IsKeyPressed(.UP) 
			{
				frogger_move_direction.y = -1
				gmem.frogger_sprite_rotation = 0
				timer_start(&frogger_anim_timer)
			} 
			else if rl.IsKeyPressed(.DOWN) 
			{
				frogger_move_direction.y = 1
				gmem.frogger_sprite_rotation = 180
				timer_start(&frogger_anim_timer)
			}

			did_frogger_request_move := frogger_move_direction != [2]f32{0,0}

			if did_frogger_request_move 
			{
				frogger_next_pos := gmem.frogger_pos + frogger_move_direction
				frogger_next_center_pos := frogger_next_pos + 0.5
				
				will_frogger_be_out_of_left_bounds :=  frogger_next_center_pos.x < 0 && frogger_move_direction.x == -1
				will_frogger_be_out_of_right_bounds := frogger_next_center_pos.x > global_number_grid_cells_axis_x - 1 && frogger_move_direction.x == 1
				will_frogger_be_out_of_top_bounds := frogger_next_pos.y < 0 && frogger_move_direction.y == -1
				will_frogger_be_out_of_bottom_bounds := frogger_next_pos.y > global_number_grid_cells_axis_y - 2&& frogger_move_direction.y == 1
				
				will_frogger_be_out_of_bounds_on_next_move := will_frogger_be_out_of_left_bounds || 
					will_frogger_be_out_of_right_bounds || 
					will_frogger_be_out_of_top_bounds || 
					will_frogger_be_out_of_bottom_bounds

				frogger_center_pos := gmem.frogger_pos + 0.5
				if will_frogger_be_out_of_left_bounds && !(frogger_center_pos.x < 0) 
				{
					timer_start(&gmem.frogger_move_lerp_timer)
					gmem.frogger_move_lerp_start_pos = gmem.frogger_pos
					frogger_next_pos.x = 0
					gmem.frogger_move_lerp_end_pos = frogger_next_pos
				}
				else if will_frogger_be_out_of_right_bounds && !(frogger_center_pos.x > global_number_grid_cells_axis_x)
				{
					timer_start(&gmem.frogger_move_lerp_timer)
					gmem.frogger_move_lerp_start_pos = gmem.frogger_pos
					frogger_next_pos.x = global_number_grid_cells_axis_x - 1
					gmem.frogger_move_lerp_end_pos = frogger_next_pos
				}
				else if !will_frogger_be_out_of_bounds_on_next_move
				{
					timer_start(&gmem.frogger_move_lerp_timer)
					gmem.frogger_move_lerp_start_pos = gmem.frogger_pos
					gmem.frogger_move_lerp_end_pos = frogger_next_pos
				}
			}
		}

		{ // frogger get points for moving up
			point_value : int = 10
			should_award_points := gmem.frogger_pos.y <= gmem.score_frogger_max_y_tracker
			if should_award_points
			{
				gmem.score_frogger_max_y_tracker -= 1
				gmem.score += point_value
			}
		}


		should_process_lily_movement := !gmem.is_lily_on_frogger
		
		if should_process_lily_movement 
		{ 
			entity_that_lily_is_on := entities[lily_logs_to_spawn_on[lily_log_to_spawn_on_index]]

			if timer_is_complete(lily_lerp_timer)
			{
				timer_advance(&lily_wait_timer, frame_time)
				if timer_is_complete(lily_wait_timer)
				{
					move_amount_x : f32 = 0 

					if lily_direction == .Right
					{
						edge_of_log_x := entity_that_lily_is_on.rectangle.width - 1
						is_lily_on_right_edge_of_log := lily_relative_log_pos_x >= edge_of_log_x
						if !is_lily_on_right_edge_of_log
						{
							move_amount_x = 1
						}
						else
						{
							lily_direction = .Left
						}
					}
					else if lily_direction == .Left
					{
						edge_of_log_x : f32 = 0
						is_lily_on_left_edge_of_log := lily_relative_log_pos_x <= edge_of_log_x
						if !is_lily_on_left_edge_of_log
						{
							move_amount_x = -1
						}
						else
						{
							lily_direction = .Right
						}
					}

					did_lily_move_amount_get_set := move_amount_x != 0

					if did_lily_move_amount_get_set
					{
						lily_lerp_relative_log_start_x = lily_relative_log_pos_x
						lily_lerp_relative_log_end_x = lily_lerp_relative_log_start_x + move_amount_x
						timer_start(&lily_lerp_timer)

					}

					timer_start(&lily_wait_timer)
				}
			}
		}

		should_check_for_lily_frogger_collision := !gmem.is_lily_on_frogger

		if should_check_for_lily_frogger_collision
		{
			frogger_center_pos    := gmem.frogger_pos + 0.5
			entity_that_lily_is_on   := entities[lily_logs_to_spawn_on[lily_log_to_spawn_on_index]]
			lily_relative_log_rectangle := rl.Rectangle { lily_relative_log_pos_x, 0, 1, 1 }
			lily_world_rectangle        := rl.Rectangle{ 
				lily_relative_log_rectangle.x + entity_that_lily_is_on.rectangle.x, 
				lily_relative_log_rectangle.y + entity_that_lily_is_on.rectangle.y, 
				1, 
				1 
			}
			is_frogger_intersecting_lily := rl.CheckCollisionPointRec(frogger_center_pos, lily_world_rectangle)
			if is_frogger_intersecting_lily
			{
				gmem.is_lily_on_frogger = true
			}

		}
		

		should_process_frogger_lerp_timer := !timer_is_complete(gmem.frogger_move_lerp_timer)
		if should_process_frogger_lerp_timer 
		{
			timer_advance(&gmem.frogger_move_lerp_timer, frame_time)
			t := timer_percentage(gmem.frogger_move_lerp_timer)
			t = min(t, 1.0)
			gmem.frogger_pos.x = (1.0 - t) * gmem.frogger_move_lerp_start_pos.x + t * gmem.frogger_move_lerp_end_pos.x
			gmem.frogger_pos.y = (1.0 - t) * gmem.frogger_move_lerp_start_pos.y + t * gmem.frogger_move_lerp_end_pos.y
		}


		should_process_lily_lerp_timer := !timer_is_complete(lily_lerp_timer)
		if should_process_lily_lerp_timer
		{
			timer_advance(&lily_lerp_timer, frame_time)
			t := timer_percentage(lily_lerp_timer)
			t = min(t, 1.0)
			lily_relative_log_pos_x = (1.0 - t) * lily_lerp_relative_log_start_x + t * lily_lerp_relative_log_end_x
		}


		{
			timer_advance(&frogger_anim_timer, frame_time)
			timer_advance(&gmem.timer_is_active_score_100, frame_time)
			timer_advance(&gmem.timer_is_active_score_200, frame_time)
		}


		{ // frogger death animation
			if animation_timer_is_playing(gmem.frogger_is_dying_timer)
			{
				animation_timer_advance(&gmem.frogger_is_dying_timer, len(frogger_is_dying_animation_frames), frogger_is_dying_animation_fps, frame_time)
				did_complete := animation_timer_is_complete(gmem.frogger_is_dying_timer, len(frogger_is_dying_animation_frames), frogger_is_dying_animation_fps)
				if did_complete
				{
					frogger_reset(frogger_start_pos)
				}
			}			
		}


		{ // turtles animation
			regular_turtles_anim_timer += frame_time
			for &timer in diving_turtles_anim_timers
			{
				timer  += frame_time
			}
		}


		if !timer_is_playing(gmem.level_end_timer) { // fly 
			timer_advance(&fly_timer, frame_time)
			if timer_is_complete(fly_timer)
			{
				timer_start(&fly_timer)
				fly_is_active = !fly_is_active
				fly_lilypad_index += 1
				if fly_lilypad_index >= len(fly_lilypad_indices)
				{
					fly_lilypad_index = 0
				}
				for gmem.is_frog_on_lilypads[fly_lilypad_indices[fly_lilypad_index]]
				{
					fly_lilypad_index += 1
					if fly_lilypad_index >= len(fly_lilypad_indices)
					{
						fly_lilypad_index = 0
					}
				}
			}
		}


		{ // move entities
			move_entities_and_wrap(entities, frame_time)
		}


		should_process_moving_frogger_with_intersecting_entities := !animation_timer_is_playing(gmem.frogger_is_dying_timer) 
		if should_process_moving_frogger_with_intersecting_entities
		{ 
			gmem.frogger_pos, gmem.frogger_move_lerp_end_pos = move_frogger_with_intersecting_entities(gmem.frogger_pos, gmem.frogger_move_lerp_end_pos, entities, frame_time)
		}


		should_check_for_win_condtions := !animation_timer_is_playing(gmem.frogger_is_dying_timer) && !timer_is_playing(gmem.level_end_timer)
		
		if should_check_for_win_condtions 
		{
			for lilypad, i in lilypads 
			{	
				frogger_center_pos := gmem.frogger_pos + 0.5
				is_frogger_on_lilypad := rl.CheckCollisionPointRec(frogger_center_pos, lilypad)
				is_there_already_a_frog_here := gmem.is_frog_on_lilypads[i]
				did_get_frogger_home := is_frogger_on_lilypad && !is_there_already_a_frog_here
				
				if did_get_frogger_home 
				{
					gmem.is_frog_on_lilypads[i] = true

					// NOTE(jblat): The extra 10 is essentially to give the effect of getting the 10 points from advancing a tile
					score_amount_get_frogger_home := 110
					gmem.score += score_amount_get_frogger_home
					

					did_frogger_get_fly := fly_lilypad_indices[fly_lilypad_index] == i && fly_is_active
					if did_frogger_get_fly
					{
						score_amount_frogger_get_fly := 100
						gmem.score += score_amount_frogger_get_fly
						timer_start(&gmem.timer_is_active_score_100)
						gmem.pos_score_100.x = lilypad.x
						gmem.pos_score_100.y = lilypad.y - 1
					}

					if gmem.is_lily_on_frogger
					{
						score_amount_get_lily_home := 200
						gmem.score += score_amount_get_lily_home
						timer_start(&gmem.timer_is_active_score_200)
						gmem.pos_score_200.x = lilypad.x
						gmem.pos_score_200.y = lilypad.y - 1
						if did_frogger_get_fly
						{
							// make more room
							gmem.pos_score_200.y -= 1
						}
					}

					frogger_reset(frogger_start_pos)
				}
			}

			number_of_frogs_on_lilypad := 0
			for present in gmem.is_frog_on_lilypads
			{
				if present
				{
					number_of_frogs_on_lilypad += 1
				}
			}

			is_all_frogs_on_lilypads := number_of_frogs_on_lilypad == len(gmem.is_frog_on_lilypads)
			if is_all_frogs_on_lilypads
			{
				timer_start(&gmem.level_end_timer)
			}
		}

		{ // level end timer
			if !timer_is_complete(gmem.level_end_timer)
			{
				timer_advance(&gmem.level_end_timer, frame_time)
				if timer_is_complete(gmem.level_end_timer)
				{
					for &present in gmem.is_frog_on_lilypads
					{
						present = false
					}
				}
			}
			
		}


		should_check_for_frogger_is_killed := !animation_timer_is_playing(gmem.frogger_is_dying_timer)  && !gmem.dbg_is_frogger_unkillable
		if should_check_for_frogger_is_killed 
		{
			is_frogger_out_of_bounds := gmem.frogger_pos.x + 0.5 < 0 || gmem.frogger_pos.x - 0.5 >= global_number_grid_cells_axis_x -1 || gmem.frogger_pos.y < 0 || gmem.frogger_pos.y > global_number_grid_cells_axis_y
			if is_frogger_out_of_bounds 
			{
				frogger_is_dying_animation_frames = frogger_is_dying_ripple_animation_frames[:]
				frogger_start_dying()
			}

			frogger_center_pos := gmem.frogger_pos + 0.5
			for entity in entities
			{
				is_frogger_intersecting_entity := rl.CheckCollisionPointRec(frogger_center_pos, entity.rectangle)
				can_entity_kill_frogger := entity.collision_behavior == .Kill_Frogger
				is_frogger_hit_by_entity := is_frogger_intersecting_entity && can_entity_kill_frogger

				if is_frogger_hit_by_entity
				{
					frogger_is_dying_animation_frames = frogger_is_dying_splat_animation_frames[:]
					frogger_start_dying()
				}
			}

			is_frogger_on_safe_entity := false
			is_frogger_moving := !timer_is_complete(gmem.frogger_move_lerp_timer)
			is_frogger_in_river_region := frogger_center_pos.y > river.y && frogger_center_pos.y < river.y + river.height
			is_frogger_in_riverbed := rl.CheckCollisionPointRec(frogger_center_pos, riverbed)

			is_frogger_on_one_of_the_open_lilypads := false
			for lilypad, i in lilypads
			{
				is_frogger_on_lilypad := rl.CheckCollisionPointRec(frogger_center_pos, lilypad)
				is_frog_already_here := gmem.is_frog_on_lilypads[i]
				is_frogger_on_one_of_the_open_lilypads = is_frogger_on_one_of_the_open_lilypads || (is_frogger_on_lilypad && !is_frog_already_here)
			}

			did_frogger_collide_with_riverbed := is_frogger_in_riverbed && !is_frogger_on_one_of_the_open_lilypads

			if did_frogger_collide_with_riverbed
			{
				frogger_is_dying_animation_frames = frogger_is_dying_ripple_animation_frames[:]
				frogger_start_dying()
			}

			for entity in entities
			{
				is_frogger_center_pos_inside_entity := rl.CheckCollisionPointRec(frogger_center_pos, entity.rectangle)

				does_entity_keep_frogger_safe := entity.collision_behavior == .Move_Frogger			

				if is_frogger_center_pos_inside_entity
				{
					is_frogger_on_safe_entity = true
				}
			}

			for turtle in entities
			{
				#partial switch a in turtle.sprite_data
				{
					case Diving_Turtle_Animation:
					{
						is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos,  turtle.rectangle)
						anim_timer := diving_turtles_anim_timers[a.timer_id]
						current_diving_turtle_frame := animation_get_current_frame(anim_timer, diving_turtles_anim_fps, len(diving_turtle_anim_frames))
						is_turtle_above_water := diving_turtle_underwater_frame != current_diving_turtle_frame
						if is_frogger_center_pos_inside_turtle_rectangle && !is_turtle_above_water
						{
							is_frogger_on_safe_entity = false
						}
					}
				}
				
			}

			did_frogger_fall_in_river := !is_frogger_on_safe_entity && is_frogger_in_river_region

			if did_frogger_fall_in_river
			{
				frogger_is_dying_animation_frames = frogger_is_dying_ripple_animation_frames[:]
				frogger_start_dying()
			}

		}	
	}



	{ // debug options
		if rl.IsKeyPressed(.F1) 
		{
			gmem.dbg_show_grid = !gmem.dbg_show_grid
		}

		if rl.IsKeyPressed(.F2)
		{
			gmem.dbg_is_frogger_unkillable = !gmem.dbg_is_frogger_unkillable
		}

		if rl.IsKeyPressed(.F3)
		{
			gmem.dbg_show_entity_bounding_rectangles = !gmem.dbg_show_entity_bounding_rectangles
		}

	}

	// rendering

	screen_width := f32(rl.GetScreenWidth())
	screen_height := f32(rl.GetScreenHeight())

	// NOTE(jblat): For mouse, see: https://github.com/raysan5/raylib/blob/master/examples/core/core_window_letterbox.c

	{ // DRAW TO RENDER TEXTURE
		rl.BeginTextureMode(gmem.game_render_target)
		defer rl.EndTextureMode()


		rl.ClearBackground(rl.LIGHTGRAY) 

		{ // draw background
			scale : f32 =  global_grid_cell_size / global_sprite_sheet_cell_size
			rl.DrawTextureEx(gmem.texture_background, [2]f32{0,0}, 0, scale, rl.WHITE)
		}


		{ // draw obstacles
			for entity, i in entities 
			{
				switch sd in entity.sprite_data
				{
					case Sprite_Sheet_Clip:
					{
						draw_sprite_sheet_clip_on_grid(sd, entity.rectangle, global_grid_cell_size, 0)
					}
					case Regular_Turtle_Animation:
					{
						regular_turtles_current_frame_sprite_sheet_clip_rectangle := animation_get_frame_sprite_clip(regular_turtles_anim_timer, regular_turtles_anim_fps, regular_turtle_anim_frames[:])
						rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, regular_turtles_current_frame_sprite_sheet_clip_rectangle,  global_sprite_sheet_cell_size, entity.rectangle, global_grid_cell_size, 0)
					}
					case Diving_Turtle_Animation:
					{
						anim_timer := diving_turtles_anim_timers[sd.timer_id]
						diving_turtles_current_frame_sprite_sheet_clilp_rectangle := animation_get_frame_sprite_clip(anim_timer, diving_turtles_anim_fps, diving_turtle_anim_frames[:])
						rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, diving_turtles_current_frame_sprite_sheet_clilp_rectangle,  global_sprite_sheet_cell_size, entity.rectangle, global_grid_cell_size, 0)	
					}
				}
			}

		}


		{ // draw fly
			clip := fly_is_active ? global_sprite_sheet_clips[.Fly] : rl.Rectangle {}
			lilypad_index := fly_lilypad_indices[fly_lilypad_index%len(fly_lilypad_indices)]
			dst_rect := lilypads[lilypad_index]
			rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, clip, global_sprite_sheet_cell_size,  dst_rect, global_grid_cell_size, 0)
		}

		
		{ // draw frogs on lilypads
			for lp, i in lilypads
			{	
				is_there_a_frog_on_this_lilypad := gmem.is_frog_on_lilypads[i]
				if is_there_a_frog_on_this_lilypad
				{
					rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, global_sprite_sheet_clips[.Happy_Frog_Closed_Mouth], global_sprite_sheet_cell_size,  lp, global_grid_cell_size, 0)
				}
			}
		}

		{ // draw frogger
			anim_timer    : f32 =    animation_timer_is_playing(gmem.frogger_is_dying_timer) ? gmem.frogger_is_dying_timer.t     : frogger_anim_timer.amount
			anim_fps      : f32 =    animation_timer_is_playing(gmem.frogger_is_dying_timer) ? frogger_is_dying_animation_fps       : 12.0 
			frames :[]rl.Rectangle = animation_timer_is_playing(gmem.frogger_is_dying_timer) ? frogger_is_dying_animation_frames[:] : frogger_anim_frames[:]
			rotation : f32         = animation_timer_is_playing(gmem.frogger_is_dying_timer) ? 0                            : gmem.frogger_sprite_rotation
			
			current_frame_sprite_sheet_clip_rectangle := animation_get_frame_sprite_clip(anim_timer, anim_fps, frames)
			rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}
			rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, current_frame_sprite_sheet_clip_rectangle, global_sprite_sheet_cell_size, rectangle,  global_grid_cell_size, rotation)
		}

		
		{ // draw lily
			if gmem.is_lily_on_frogger
			{
				dst_rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}
				rotation := gmem.frogger_sprite_rotation
				if rotation == 0.0
				{
					dst_rectangle.y += 0.15
				}
				else if rotation == 90.0
				{
					dst_rectangle.x -= 0.15
				}
				else if rotation == 180.0
				{
					dst_rectangle.y -= 0.15
				}
				else if rotation == 270.0
				{
					dst_rectangle.x += 0.15
				}
				rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, lily_sprite_sheet_clip, global_sprite_sheet_cell_size,  dst_rectangle, global_grid_cell_size, rotation)
			}
			else 
			{
				log_that_lily_is_on := lily_logs_to_spawn_on[lily_log_to_spawn_on_index]
				log := entities[log_that_lily_is_on]
				lily_world_rectangle := rl.Rectangle{
					log.rectangle.x + lily_relative_log_pos_x,
					log.rectangle.y,
					lily_width,
					lily_height
				}
				rotation := map_direction_rotation[lily_direction]
				rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, lily_sprite_sheet_clip,  global_sprite_sheet_cell_size, lily_world_rectangle, global_grid_cell_size, rotation)
			}
		}

		if timer_is_playing(gmem.timer_is_active_score_100)
		{
			dst_rect := rl.Rectangle {gmem.pos_score_100.x, gmem.pos_score_100.y, 1, 1}
			rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, global_sprite_clip_score_100,  global_sprite_sheet_cell_size, dst_rect, global_grid_cell_size, 0)
		}

		if timer_is_playing(gmem.timer_is_active_score_200)
		{
			dst_rect := rl.Rectangle {gmem.pos_score_200.x, gmem.pos_score_200.y, 1, 1}
			rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, global_sprite_clip_score_200,  global_sprite_sheet_cell_size, dst_rect, global_grid_cell_size, 0)			
		}
	
		if gmem.dbg_show_grid 
		{ 	
			for x : f32 = 0; x < global_number_grid_cells_axis_x; x += 1 
			{
				render_x := x * global_grid_cell_size
				render_start_y : f32 = 0
				render_end_y := global_game_view_pixels_height
				rl.DrawLineV([2]f32{render_x, render_start_y}, [2]f32{render_x, render_end_y}, rl.WHITE)
			}

			for y : f32 = 0; y < global_number_grid_cells_axis_y; y += 1 
			{
				render_y := y * global_grid_cell_size
				render_start_x : f32 = 0
				render_end_x := global_game_view_pixels_width
				rl.DrawLineV([2]f32{render_start_x, render_y}, [2]f32{render_end_x, render_y}, rl.WHITE)
			}
		}

		
		if gmem.dbg_show_entity_bounding_rectangles
		{	
			frogger_rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}
			rlgrid.draw_rectangle_lines_on_grid(frogger_rectangle, 4, rl.GREEN, global_grid_cell_size)

			// TODO(jblat): draw the rest of the stuff like logs and whatnot
		}

		
		{ // heads up display
			heads_up_display_font_size : f32 = 0.7

			one_up_pos := [2]f32{4,0}

			rlgrid.draw_text_on_grid_right_justified(gmem.font, "1-UP", one_up_pos, heads_up_display_font_size, 0, rl.WHITE, f32(global_grid_cell_size))

			score_text := fmt.ctprintf("%05d", gmem.score)
			score_text_pos := [2]f32 {
				one_up_pos.x,
				one_up_pos.y + heads_up_display_font_size
			}

			rlgrid.draw_text_on_grid_right_justified(gmem.font, score_text, score_text_pos, heads_up_display_font_size, 0, rl.WHITE, f32(global_grid_cell_size))

			if !timer_is_complete(gmem.level_end_timer)
			{
				text_get_ready : cstring = "get ready for next level!"
				rlgrid.draw_text_on_grid_centered(gmem.font, text_get_ready, [2]f32{global_number_grid_cells_axis_x/2, 8}, heads_up_display_font_size, 0, rl.WHITE, f32(global_grid_cell_size))
			}
		}	
	}


	{ // DRAW TO WINDOW
		rl.BeginDrawing()
		rl.BeginShaderMode(gmem.shader_pixel_filter)
		// rl.BeginBlendMode(.ALPHA_PREMULTIPLY)
		rl.ClearBackground(rl.BLACK)

		src := rl.Rectangle{ 0, 0, f32(gmem.game_render_target.texture.width), f32(-gmem.game_render_target.texture.height) }
		
		scale := min(screen_width/global_game_view_pixels_width, screen_height/global_game_view_pixels_height)

		window_scaled_width  := global_game_view_pixels_width * scale
		window_scaled_height := global_game_view_pixels_height * scale

		dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}
		rl.DrawTexturePro(gmem.game_render_target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)

		rl.EndShaderMode()
		// rl.EndBlendMode()
		rl.EndDrawing()

	}

	free_all(context.temp_allocator)
}

@(export)
game_shutdown :: proc()
{
	window_pos    := rl.GetWindowPosition()
	screen_width  := rl.GetScreenWidth()
	screen_height := rl.GetScreenHeight()

	window_save_data := Window_Save_Data {i32(window_pos.x), i32(window_pos.y), screen_width, screen_height}
	bytes_window_save_data := mem.ptr_to_bytes(&window_save_data)
	file_window_save_data, err := os2.open(global_filename_window_save_data, {.Write, .Create})
	if err != nil
	{
		fmt.printfln("Error opening/creating Window Save Data File: %v", err)
	}
	n_bytes_written, write_err := os2.write(file_window_save_data, bytes_window_save_data)
	if write_err != nil
	{
		fmt.printfln("Error saving Window Save Data: %v", write_err)
	}
	did_not_write_all_bytes :=  n_bytes_written != size_of(window_save_data)
	if did_not_write_all_bytes
	{
		fmt.printfln("Error saving Window Save Data: number bytes written = %v, number bytes expected = %v", n_bytes_written, size_of(window_save_data))
	}
}