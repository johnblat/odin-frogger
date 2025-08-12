package game

import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:c"

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
	Sprite_Clip_Name,
	Animation_Player_Name,
}



Collision_Behavior :: enum {
	Move_Frogger,
	Kill_Frogger,
}


Entity_Behavior :: enum {
	Row_Obstacle,
	Snake,
	Otter,
	Alligator,
}


Entity :: struct
{
	rectangle : rl.Rectangle, // what is the hitbox? and where should we draw the entity?
	speed     : f32, // how fast does the entity move
	sprite_data: Sprite_Data, // either a single sprite or an animated sprite
	collision_behavior: Collision_Behavior, // what should this entity do to frogger?
	snake_behavior: Snake_Behavior_State, // only used if a snake
	row_id: u32,
}


Root_State :: enum {
	Main_Menu,
	Game,
	// Enter_High_Score,
}


// This struct contains all data we want to preserve on hot-reloads
// a hot reload is compiling the game while it is running so we dont have to close and restart the game
// each time a change is made to the code
Game_Memory :: struct 
{	
	root_state : Root_State,

	// VIEW
	game_render_target: rl.RenderTexture,

	// Spritesheets
	texture_sprite_sheet : rl.Texture2D,
	texture_background   : rl.Texture2D,

	speed_multiplier_difficulty: f32,

	// Font
	font :rl.Font,

	// DEBUG
	dbg_show_grid : bool,
	dbg_show_level: bool,
	dbg_is_frogger_unkillable : bool,
	dbg_show_entity_bounding_rectangles : bool,
	dbg_speed_multiplier: f32,
	dbg_camera_offset_to_left: f32,
	dbg_camera_zoom :f32,
	dbg_timer_lose_life_pause: bool,

	// GAME

	animation_player_frogger_is_dying: Animation_Player,

	countdown_timer_lose_life: f32,

	level_current : int,

	// frogger
	frogger_pos       : [2]f32,
	frogger_move_lerp_timer     : Timer,
	frogger_move_lerp_start_pos : [2]f32,
	frogger_move_lerp_end_pos   : [2]f32,

	frogger_sprite_rotation: f32,

	is_lily_on_frogger : bool,

	// win
	is_frogs_on_lilypads :[5]bool,
	level_end_timer :Timer,

	// score
	score :int,
	score_frogger_max_y_tracker : f32,

	timer_is_active_score_100: Timer,
	timer_is_active_score_200: Timer,

	pos_score_100: [2]f32,
	pos_score_200: [2]f32,

	pause : bool,

	lives: u32,
	counter_cycle: int,
	counter_level: int,

	// shader
	shader_pixel_filter: rl.Shader,

	level_index: u32,

	last_cycle_completion_in_seconds : i32,
	countdown_timer_display_last_cycle_completion: f32,

	countdown_timer_game_over_display: f32,
}

global_countdown_timer_duration_display_last_cycle_completion : f32 = 4.0
global_countdown_timer_game_over_display: f32 = 3.0

gmem: ^Game_Memory

music :rl.Sound

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


entity_move :: proc(entity: ^Entity, move_amount_x, dt: f32)
{
	entity.rectangle.x += move_amount_x * dt * gmem.dbg_speed_multiplier * gmem.speed_multiplier_difficulty
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

	// bytes_window_save_data, err := os2.read_entire_file_from_path(global_filename_window_save_data, context.temp_allocator)
	bytes_window_save_data, ok := read_entire_file(global_filename_window_save_data, context.temp_allocator)

	if ok == false
	{
		fmt.printfln("Error reading from window save data file: %v", ok)
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
	
	rl.InitAudioDevice()
	// music = rl.LoadSound("assets/froggerGameThemeOne.mp3")
	// rl.PlaySound(music)
	rl.SetTargetFPS(60)
}


is_frogs_on_lilypads := [5]bool{false, false, false, false, false}

Row :: struct {
	start_x: f32,
	speed: f32,
}

rows_by_level := [?][16]Row {
	rows_level_1,
	rows_level_2,
	rows_level_3,
	rows_level_4,
	rows_level_5,
}


entities_by_level := [?][]Entity {
	entities_level_1[:],
	entities_level_2[:],
	entities_level_3[:],
	entities_level_4[:],
	entities_level_5[:],
}


rows_level_1 := [16]Row {
	{start_x = 0,    speed = 0},
	{start_x = 0,    speed = 0},
	{start_x = 0,    speed = 0},
	{start_x = -9,   speed = 1.2},
	{start_x = -3.5, speed = -1.5},
	{start_x = -10,  speed = 3},
	{start_x = -6,   speed = 0.8},
	{start_x = -2,   speed = -1.5},
	{start_x = 0,    speed = 0},
	{start_x = -2,   speed = -1.5},
	{start_x = -1,   speed = 1},
	{start_x = -1,   speed = -0.8},
	{start_x = -1,   speed = 0.6},
	{start_x = -1,   speed = -0.6},
	{start_x = 0,    speed = 0},
	{start_x = 0,    speed = 0},
}


entities_level_1 := [?]Entity {
    { rectangle = {0    ,  3, 4, 1},   speed = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {6    ,  3, 4, 1},   speed = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {12   , 3, 4, 1},   speed  = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {18   , 3, 4, 1},   speed  = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {2    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {3    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {6    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {7    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {10   , 4, 1, 1},   speed  = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {11   , 4, 1, 1},   speed  = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {15.5 , 4, 1, 1}, speed    = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Diving_Turtle_0, collision_behavior             = .Move_Frogger },
    { rectangle = {16.5 , 4, 1, 1}, speed    = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Diving_Turtle_0, collision_behavior             = .Move_Frogger },
    { rectangle = {0    ,  5, 6, 1},   speed = 3,     row_id =  5,   sprite_data = .Long_Log,                               collision_behavior           = .Move_Frogger},
    { rectangle = {8    ,  5, 6, 1},   speed = 3,     row_id =  5,   sprite_data = .Long_Log,                               collision_behavior           = .Move_Frogger},
    { rectangle = {16   , 5, 6, 1},   speed  = 3,     row_id =  5,   sprite_data = .Long_Log,                               collision_behavior           = .Move_Frogger},
    { rectangle = {0    ,  6, 3, 1},   speed = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {5    ,  6, 3, 1},   speed = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {10   , 6, 3, 1},   speed  = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {15   , 6, 3, 1},   speed  = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {0    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {1    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {2    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {4    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {5    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {6    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {8    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {9    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {10   , 7, 1, 1},   speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {12   ,   7, 1, 1}, speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Diving_Turtle_1, collision_behavior             = .Move_Frogger },
    { rectangle = {13   ,   7, 1, 1}, speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Diving_Turtle_1, collision_behavior             = .Move_Frogger },
    { rectangle = {14   ,   7, 1, 1}, speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Diving_Turtle_1, collision_behavior             = .Move_Frogger },
    { rectangle = {1    ,   9, 2, 1},  speed = -1.5  , row_id = 9, sprite_data     = .Truck,                                  collision_behavior           = .Kill_Frogger},
    { rectangle = {6.5  , 9, 2, 1},  speed   = -1.5  , row_id = 9, sprite_data     = .Truck,                                  collision_behavior           = .Kill_Frogger},
    { rectangle = {1    ,  10, 1, 1},  speed = 1  ,    row_id = 10, sprite_data   = .Racecar,                                collision_behavior           = .Kill_Frogger},
    { rectangle = {10   , 11, 1, 1},  speed  = -0.8  , row_id = 11, sprite_data     = .Purple_Car,                             collision_behavior           = .Kill_Frogger},
    { rectangle = {6    ,  11, 1, 1},  speed = -0.8  , row_id = 11, sprite_data     = .Purple_Car,                             collision_behavior           = .Kill_Frogger},
    { rectangle = {2    ,  11, 1, 1},  speed = -0.8  , row_id = 11, sprite_data     = .Purple_Car,                             collision_behavior           = .Kill_Frogger},
    { rectangle = {5    ,  12, 1, 1},  speed = 0.6  ,  row_id = 12, sprite_data     = .Bulldozer,                              collision_behavior           = .Kill_Frogger},
    { rectangle = {9    ,  12, 1, 1},  speed = 0.6  ,  row_id = 12, sprite_data     = .Bulldozer,                              collision_behavior           = .Kill_Frogger},
    { rectangle = {13   , 12, 1, 1},  speed  = 0.6  ,  row_id = 12, sprite_data     = .Bulldozer,                              collision_behavior           = .Kill_Frogger},
    { rectangle = {10   , 13, 1, 1},  speed  = -0.6  , row_id = 13, sprite_data     = .Taxi,                                   collision_behavior           = .Kill_Frogger},
    { rectangle = {6    ,  13, 1, 1},  speed = -0.6  , row_id = 13, sprite_data     = .Taxi,                                   collision_behavior           = .Kill_Frogger},
    { rectangle = {2    ,  13, 1, 1},  speed = -0.6  , row_id = 13, sprite_data     = .Taxi,                                   collision_behavior           = .Kill_Frogger},
}
// 15

rows_level_2 := [16]Row {
	{start_x = 0,     speed = 0},
	{start_x = 0,     speed = 0},
	{start_x = 0,     speed = 0},
	{start_x = -15,   speed = 1.2},
	{start_x = -2.5,  speed = -2},
	{start_x = -18,   speed = 2},
	{start_x = -3,    speed = 0.8},
	{start_x = -2,    speed = -2},
	{start_x = 0,     speed = 0},
	{start_x = -3,    speed = -1.5},
	{start_x = -1,    speed = 1},
	{start_x = -4,    speed = -2},
	{start_x = -2,    speed = 2},
	{start_x = -4,    speed = -2},
	{start_x = 0,     speed = 0},
	{start_x = 0,     speed = 0},
}

entities_level_2 := [?]Entity {
    { rectangle = {0,  3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {6,  3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {12, 3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {18, 3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {24, 3, 3, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {2,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {3,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {5,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {8, 4, 1, 1},     speed = -2,    row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {9, 4, 1, 1},     speed = -2,    row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {11, 4, 1, 1},     speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12, 4, 1, 1},     speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {15.5, 4, 1, 1},   speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {16.5, 4, 1, 1},   speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {0,  5, 6, 1},     speed = 2,    row_id = 5,  collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,    row_id = 5,  collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,  row_id = 6,   collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {5,    6, 3, 1},   speed = 0.8,  row_id = 6,   collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {10,   6, 3, 1},   speed = 0.8,  row_id = 6,   collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {2,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {3,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {4,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {8,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {9,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {13,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {14,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   9, 2, 1},  speed = -1.5,   row_id = 9, collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {6.5, 9, 2, 1},  speed = -1.5,   row_id = 9, collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {12, 9, 2, 1},  speed = -1.5,    row_id = 9, collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {1,  10, 1, 1},  speed = 1  ,    row_id = 10, collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {3.5,  10, 1, 1},  speed = 1  ,  row_id = 10,  collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},  speed = -2  ,    row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {2.5,  11, 1, 1},  speed = -2  , row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {6.5,  11, 1, 1},  speed = -2  , row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {12,  11, 1, 1},  speed = -2  ,  row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {0,  12, 1, 1},  speed = 2  ,    row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,    row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,     row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,    row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},  speed = -2  ,    row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {2.5,  13, 1, 1},  speed = -2  , row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {6.5,  13, 1, 1},  speed = -2  , row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {12,  13, 1, 1},  speed = -2  ,  row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

// 17


rows_level_3 := [16]Row {
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = -18, speed = 1.2},
	{start_x = -4,  speed = -2},
	{start_x = -18, speed = 2},
	{start_x = -3,  speed = 0.8},
	{start_x = -3,  speed = -3.5},
	{start_x = 0,   speed = 0},
	{start_x = -3,  speed = -1.5},
	{start_x = -1,  speed = 3},
	{start_x = -4,  speed = -3},
	{start_x = -1,  speed = 2},
	{start_x = -2,  speed = -1.5},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
}

entities_level_3 := [?]Entity {
    { rectangle = {0.5, 3, 3, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {11,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {17,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {27.5, 3, 4, 1},    speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {1,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {2,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {5.5, 4, 1, 1},     speed = -2,    row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6.5, 4, 1, 1},     speed = -2,    row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {11, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {14.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {15.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,  5, 6, 1},     speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {5,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {10,   6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {0,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {2,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {5,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {7,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {11,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12,   7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {1,   9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {6.5, 9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {12, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {1,  10, 1, 1},  speed = 3  ,      row_id = 10,     collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {5.5,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},     speed = -3  ,   row_id = 11,        collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {2.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {6.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {12,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {0,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,       row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},     speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {4,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {8,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {12,  13, 1, 1},   speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

// 14

rows_level_4 := [16]Row {
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = -18, speed = 2},
	{start_x = -4,  speed = -2},
	{start_x = -18, speed = 2},
	{start_x = -10,  speed = 1.5},
	{start_x = -3,  speed = -3.5},
	{start_x = 0,   speed = 0},
	{start_x = -4.5,  speed = -1.5},
	{start_x = -5,  speed = 6},
	{start_x = -4,  speed = -3},
	{start_x = -1,  speed = 2},
	{start_x = -4,  speed = -1.5},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
}

entities_level_4 := [?]Entity {
    { rectangle = {0.5, 3, 3, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {11,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {17,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {27.5, 3, 4, 1},    speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {1,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {2,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    // TODO(jalfonso): this gap is not supposed to be as big
    { rectangle = {10, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {11, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {14.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {15.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,  5, 6, 1},     speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {8,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {17,   6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {0,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {2,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {5,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {7,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {11,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12,   7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,   9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {4.5, 9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {9, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {13.5, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {1,  10, 1, 1},  speed = 3  ,      row_id = 10,     collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {5.5,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {10,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},     speed = -3  ,   row_id = 11,        collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {2.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {6.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {12,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {0,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,       row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},     speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {5,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {10,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {15,  13, 1, 1},   speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

rows_level_5 := [16]Row {
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = -18, speed = 2},
	{start_x = -6,  speed = -2},
	{start_x = -18, speed = 2},
	{start_x = -10,  speed = 1.5},
	{start_x = -3,  speed = -2},
	{start_x = 0,   speed = 0},
	{start_x = -6,  speed = -1.5},
	{start_x = -5,  speed = 6},
	{start_x = -4,  speed = -3},
	{start_x = -2,  speed = 2},
	{start_x = -4,  speed = -1.5},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
}

entities_level_5 := [?]Entity {
    { rectangle = {0.5, 3, 3, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {17,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {0,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {1,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6.5, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {7.5, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {13,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {14,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,  5, 6, 1},     speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {8,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {17,   6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {0,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {2,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {7,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {8,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {9,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,   9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {4.5, 9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {9, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {0,  10, 1, 1},  speed = 3  ,      row_id = 10,     collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {4,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {8,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {12,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},     speed = -3  ,   row_id = 11,        collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {3.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {7,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {10.5,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {14,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },

    { rectangle = {0,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,       row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},     speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {5,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {10,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {15,  13, 1, 1},   speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

Otter :: struct {
	entity: Entity,
	timer_attack: Timer,
}

Spawn_Description :: struct {
	pos: [2]f32,
	speed: f32,
	attack_speed: f32,
}


otter_spawn_descriptions_level_1 := [?]Spawn_Description {}
otter_spawn_descriptions_level_2 := [?]Spawn_Description {}
otter_spawn_descriptions_level_3 := [?]Spawn_Description {
	{ pos = { -3, 3 },  speed = 2 }, 
	{ pos = { global_number_grid_cells_axis_x, 4 }, speed = -2.5 }, 
	{ pos = { -3, 5 }, speed = 2.5  }, 
	{ pos = { -3, 6 }, speed = 2 }, 
	{ pos = {global_number_grid_cells_axis_x, 7 }, speed = -4 },
}
otter_spawn_descriptions_level_4 := [?]Spawn_Description {
	{ pos = { -3, 3 },  speed = 2.5 }, 
	{ pos = { global_number_grid_cells_axis_x, 4 }, speed = -2.5 }, 
	{ pos = { -3, 5 }, speed = 2.5  }, 
	{ pos = { -3, 6 }, speed = 2 }, 
	{ pos = {global_number_grid_cells_axis_x, 7 }, speed = -4 },
}
otter_spawn_descriptions_level_5 := [?]Spawn_Description {
	{ pos = { -3, 3 },  speed = 2.5 }, 
	{ pos = { global_number_grid_cells_axis_x, 4 }, speed = -2.5 }, 
	{ pos = { -3, 5 }, speed = 2.5  }, 
	{ pos = { -3, 6 }, speed = 2 }, 
	{ pos = {global_number_grid_cells_axis_x, 7 }, speed = -4 },
}

current_otter_spawn_data_id := 0

otter_spawn_descriptions_by_level := [?][]Spawn_Description {
	otter_spawn_descriptions_level_1[:],
	otter_spawn_descriptions_level_2[:],
	otter_spawn_descriptions_level_3[:],
	otter_spawn_descriptions_level_4[:],
	otter_spawn_descriptions_level_5[:],
}


otters_by_level := [?][]Otter {
	otters_level_1[:],
	otters_level_2[:],
	otters_level_3[:],
	otters_level_4[:],
	otters_level_5[:],
}

otters_level_1 := [?]Otter{}
otters_level_2 := [?]Otter{}
otters_level_3 := [?]Otter{ 
	{ entity = { rectangle = {-1, 3, 1, 1}, speed = 2 }, timer_attack = { amount = 2.0, duration = 2.0 } } 
}
otters_level_4 := [?]Otter{ 
	{ entity = { rectangle = {-1, 3, 1, 1}, speed = 2 }, timer_attack = { amount = 2.0, duration = 2.0 } } 
}
otters_level_5 := [?]Otter{ 
	{ entity = { rectangle = {-1, 3, 1, 1}, speed = 2 }, timer_attack = { amount = 2.0, duration = 2.0 } } 
}


animation_alligator_fps : f32 = 3
animation_timer_alligator := Animation_Timer { t = 0, playing = true, loop = true }
animation_frames_alligator := [?]Sprite_Clip_Name{ .Alligator_Mouth_Closed, .Alligator_Mouth_Open }
alligator_hit_box_relative_mouth_open := rl.Rectangle{2, 0, 1, 1}


animation_frames_regular_turtles := [?]Sprite_Clip_Name{ .Turtle_Frame_0, .Turtle_Frame_1, .Turtle_Frame_2 }
animation_fps_regular_turtles : f32 = 3
animation_timer_regular_turtles := Animation_Timer { t = 0, playing = true, loop = true }

animation_frames_diving_turtles := [?]Sprite_Clip_Name{
	.Turtle_Frame_0, .Turtle_Frame_1, .Turtle_Frame_2, .Turtle_Frame_3, .Turtle_Frame_4, .Empty, .Turtle_Frame_4, .Turtle_Frame_3, 
}
animation_fps_diving_turtles : f32 = animation_fps_regular_turtles


animation_frames_frogger_dying_hit := [?]Sprite_Clip_Name {
	.Frogger_Dying_Hit_Frame_0, .Frogger_Dying_Hit_Frame_1, .Frogger_Dying_Hit_Frame_2, .Frogger_Dying_Hit_Frame_1,
	.Frogger_Dying_Hit_Frame_0, .Frogger_Dying_Hit_Frame_1, .Frogger_Dying_Hit_Frame_2, .Frogger_Dying_Hit_Frame_1,
	.Frogger_Dying_Hit_Frame_0, .Frogger_Dying_Hit_Frame_1, .Frogger_Dying_Hit_Frame_2, .Frogger_Dying_Hit_Frame_1,
	.Frogger_Dying_Hit_Frame_0, .Frogger_Dying_Hit_Frame_1, .Frogger_Dying_Hit_Frame_2, .Frogger_Dying_Hit_Frame_1,
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty, 
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty,
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty,
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty,
	.Empty,
}

// TODO(jalf): some reason, this needs to be about same length as above, or else the animation will display not right (wraps back around to beginning)
animation_frames_frogger_dying_drown := [?]Sprite_Clip_Name {
	.Frogger_Dying_Ripple_Frame_0, .Frogger_Dying_Ripple_Frame_1, .Frogger_Dying_Ripple_Frame_2,
	.Frogger_Dying_Ripple_Frame_0, .Frogger_Dying_Ripple_Frame_1, .Frogger_Dying_Ripple_Frame_2,
	.Frogger_Dying_Ripple_Frame_0, .Frogger_Dying_Ripple_Frame_1, .Frogger_Dying_Ripple_Frame_2,
	.Frogger_Dying_Ripple_Frame_0, .Frogger_Dying_Ripple_Frame_1, .Frogger_Dying_Ripple_Frame_2,
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty, 
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty,
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty,
	.Skull_And_Crossbones, .Skull_And_Crossbones, .Empty, .Empty,
	.Empty,
	.Empty,
	.Empty,
	.Empty,
	.Empty,

}

animation_frames_snake := [?]Sprite_Clip_Name {
	.Snake_Frame_0, .Snake_Frame_1, .Snake_Frame_2, .Snake_Frame_1
}

Animation_Name :: enum {
	Alligator,
	Regular_Turtle,
	Diving_Turtle,
	Frogger_Dying_Hit,
	Frogger_Dying_Drown,
	Snake,
}

Animation_Player_Name :: enum {
	Alligator,
	Regular_Turtle,
	Diving_Turtle_0,
	Diving_Turtle_1,
	Snake_0,
	Snake_1,
}

Animation_Player :: struct {
	timer: Animation_Timer,
	fps: f32,
	animation_name : Animation_Name,
}

animation_frames := [Animation_Name][]Sprite_Clip_Name {
	.Alligator = animation_frames_alligator[:],
	.Regular_Turtle =  animation_frames_regular_turtles[:],
	.Diving_Turtle = animation_frames_diving_turtles[:],
	.Frogger_Dying_Hit = animation_frames_frogger_dying_hit[:],
	.Frogger_Dying_Drown = animation_frames_frogger_dying_drown[:],
	.Snake = animation_frames_snake[:],
}


animation_players := [Animation_Player_Name]Animation_Player {
	.Alligator       = { timer = { t = 0, playing = true, loop = true }, fps = 1, animation_name = .Alligator },
	.Regular_Turtle  = { timer = { t = 0, playing = true, loop = true }, fps = 3, animation_name = .Regular_Turtle },
	.Diving_Turtle_0 = { timer = { t = 0, playing = true, loop = true }, fps = 3, animation_name = .Diving_Turtle },
	.Diving_Turtle_1 = { timer = { t = 1, playing = true, loop = true }, fps = 3, animation_name = .Diving_Turtle },
	.Snake_0         = { timer = { t = 0, playing = true, loop = true }, fps = 10, animation_name = .Snake },
	.Snake_1         = { timer = { t = 1, playing = true, loop = true }, fps = 10, animation_name = .Snake },
}

animation_player_frogger_is_dying :=  Animation_Player { timer = { t = 0, playing = false, loop = false }, animation_name = .Frogger_Dying_Hit }

animation_fps_list := [Animation_Name]f32 {
	.Alligator = 1,
	.Regular_Turtle = 3,
	.Diving_Turtle = 3,
	.Frogger_Dying_Hit = 12,
	.Frogger_Dying_Drown = 12,
	.Snake = 3,
}

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

lily_logs_to_spawn_on := [?]int{15, 17, 14, 12, 11}


Snake_Mode :: enum
{
	On_Entity,
	On_Median,
}

Snake_Behavior_State :: struct
{
	snake_mode : Snake_Mode,
	on_entity_id : int,
}

snakes_by_level := [?][]Entity {
	snakes_level_1[:],
	snakes_level_2[:],
	snakes_level_3[:],
	snakes_level_4[:],
	snakes_level_5[:],
}

snakes_level_1 := [?]Entity{}
snakes_level_2 := [?]Entity{}
snakes_level_3 := [?]Entity{
	{ rectangle = {-2, 8, 2, 1}, speed = 1, sprite_data = Animation_Player_Name.Snake_0, snake_behavior = { snake_mode = .On_Median, on_entity_id = 12 } },
}
snakes_level_4 := [?]Entity {
	{ rectangle = {-2, 8, 2, 1}, speed = 1.8, sprite_data = Animation_Player_Name.Snake_0, snake_behavior = { snake_mode = .On_Median, on_entity_id = 10 }, },
}
snakes_level_5 := [?]Entity {
	{ rectangle = {-2, 8, 2, 1}, speed = 1, sprite_data = Animation_Player_Name.Snake_0, snake_behavior = { snake_mode = .On_Median, on_entity_id = 8 }, },
	{ rectangle = {global_number_grid_cells_axis_x, 8, 2, 1}, speed = -1, sprite_data = Animation_Player_Name.Snake_1, snake_behavior = { snake_mode = .On_Median, on_entity_id = 9 } },
}




lilypad_ids_crocodile := [?]int{4, 0, 3, 1, 2, 1, 3, 0}
current_crocodile_lilypad_id_index := 0

timer_crocodile_inactive := Timer { amount = 0, duration = 6.0 }
timer_crocodile_peek     := Timer { amount = 2.0, duration = 2.0 }
timer_crocodile_attack   := Timer { amount = 1.0, duration = 1.0 }




move_entities_and_wrap :: proc(entities: []Entity, dt: f32)
{
	for &entity in entities
	{
		rectangle := &entity.rectangle
		rectangle_move_amount := rows_by_level[gmem.level_index][entity.row_id].speed * gmem.dbg_speed_multiplier * dt
		rectangle.x += rectangle_move_amount

		warp_pos_on_left_side_x := rows_by_level[gmem.level_index][entity.row_id].start_x
		should_warp_to_right_side_of_screen := rectangle_move_amount < 0 && rectangle.x < warp_pos_on_left_side_x

		warp_pos_on_right_side_x := global_number_grid_cells_axis_x 
		should_warp_to_left_side_of_screen := rectangle_move_amount > 0 && rectangle.x > warp_pos_on_right_side_x 

		if should_warp_to_right_side_of_screen
		{
			overshoot : f32 = warp_pos_on_left_side_x - rectangle.x 
			rectangle.x = global_number_grid_cells_axis_x - overshoot
		}
		else if should_warp_to_left_side_of_screen 
		{
			overshoot : f32 = rectangle.x - warp_pos_on_right_side_x 
			rectangle.x = warp_pos_on_left_side_x + overshoot
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
			speed := rows_by_level[gmem.level_index][entity.row_id].speed
			move_speed : f32 = speed * gmem.dbg_speed_multiplier
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


global_countdown_timer_lose_life_duration : f32 = 30.0

@(export)
game_init :: proc()
{

	gmem = new(Game_Memory)

	gmem.root_state = .Main_Menu

	string_fs  := strings.string_from_ptr(&bytes_aa_pixel_filter_shader[0], len(bytes_aa_pixel_filter_shader))
	cstring_fs := strings.clone_to_cstring(string_fs, context.temp_allocator)
	gmem.shader_pixel_filter = rl.LoadShaderFromMemory(nil, cstring_fs)
	game_render_target := rl.LoadRenderTexture(i32(global_game_view_pixels_width), i32(global_game_view_pixels_height))
	rl.SetTextureFilter(game_render_target.texture, rl.TextureFilter.BILINEAR)
	rl.SetTextureWrap(game_render_target.texture, .CLAMP) // this stops sub-pixel artifacts on edges of game texture

	gmem.game_render_target = game_render_target

	gmem.dbg_show_grid = false
	gmem.dbg_is_frogger_unkillable = false

	gmem.frogger_pos = [2]f32{7,14}
	gmem.frogger_move_lerp_timer = Timer {
		amount = frogger_move_lerp_duration,
		duration = frogger_move_lerp_duration,
	}

	gmem.is_frogs_on_lilypads = is_frogs_on_lilypads

	image_sprite_sheet := rl.LoadImageFromMemory(".png", &bytes_image_data_sprite_sheet_bytes[0], i32(len(bytes_image_data_sprite_sheet_bytes)))
	image_background   := rl.LoadImageFromMemory(".png", &bytes_image_data_background[0], i32(len(bytes_image_data_background)))

	gmem.texture_sprite_sheet = rl.LoadTextureFromImage(image_sprite_sheet)
	rl.SetTextureFilter(gmem.texture_sprite_sheet, rl.TextureFilter.POINT)
	rl.SetTextureWrap(gmem.texture_sprite_sheet, .CLAMP) // NOTE(jalfonso) idk - this might not be necesarry - but wanted to add it to see if it removes subpixel artifacts on some machines i've tested on
	gmem.texture_background   = rl.LoadTextureFromImage(image_background)

	gmem.font = rl.LoadFontFromMemory(".otf", &bytes_font_data[0], i32(len(bytes_font_data)), 256, nil, 0)

	gmem.score_frogger_max_y_tracker = gmem.frogger_pos.y - 1

	gmem.level_end_timer = Timer{
		amount = 6.0,
		duration = 6.0,
		loop = false,
	}

	gmem.timer_is_active_score_100 = timer_init(2.0, false)
	gmem.timer_is_active_score_200 = timer_init(2.0, false)

	gmem.animation_player_frogger_is_dying = { timer = { t = 0, playing = false, loop = false }, animation_name = .Frogger_Dying_Hit }

	gmem.dbg_camera_zoom = 1.0

	gmem.countdown_timer_lose_life = global_countdown_timer_lose_life_duration

	gmem.dbg_speed_multiplier = 1.0

	gmem.level_index = 0

	gmem.lives = 3

}

score_increment :: proc(amount: int)
{
	old_score := gmem.score
	gmem.score += amount
	should_award_bonus_life := old_score < 20000 && gmem.score >= 20000
	if should_award_bonus_life
	{
		gmem.lives += 1
	}
}

frogger_reset :: proc()
{
	pos := [2]f32{7,14}

	gmem.frogger_pos = pos
	gmem.frogger_sprite_rotation = 0.0
	gmem.score_frogger_max_y_tracker = pos.y - 1
	gmem.is_lily_on_frogger = false
	timer_stop(&gmem.frogger_move_lerp_timer)
	gmem.countdown_timer_lose_life = global_countdown_timer_lose_life_duration
}


frogger_start_dying :: proc(animation_name: Animation_Name)
{
	gmem.animation_player_frogger_is_dying.animation_name = animation_name
	gmem.is_lily_on_frogger = false
	timer_stop(&gmem.frogger_move_lerp_timer)
	animation_timer_start(&gmem.animation_player_frogger_is_dying.timer)
	if gmem.lives != 0
	{
		gmem.lives -= 1
	}
}


root_state_main_menu_enter :: proc()
{
	frogger_reset()
	gmem.root_state = .Main_Menu
	gmem.level_index = 0
	for &is_frog_on_lilypad in gmem.is_frogs_on_lilypads
	{
		is_frog_on_lilypad = false
	}
	gmem.score = 0
}

root_state_game :: proc()
{
	entities := entities_by_level[gmem.level_index]
	otters := otters_by_level[gmem.level_index]
	otter_spawn_descriptions := otter_spawn_descriptions_by_level[gmem.level_index]
	snakes := snakes_by_level[gmem.level_index]

	if rl.IsKeyPressed(.ENTER)
	{
		gmem.pause = !gmem.pause
	}

	if rl.IsKeyPressed(.BACKSPACE)
	{
		gmem.pause = !gmem.pause
	}

	skip_next_frame := false 

	when ODIN_DEBUG
	{
		camera_mod_key := rl.KeyboardKey.C
		level_mod_key := rl.KeyboardKey.L
		frogs_on_lilypad_mod_key := rl.KeyboardKey.F

		if rl.IsKeyDown(camera_mod_key)
		{
			if rl.IsKeyDown(.LEFT_BRACKET) && rl.IsKeyDown(.RIGHT_BRACKET)
			{
				gmem.dbg_camera_offset_to_left = 0
			}
			else if rl.IsKeyPressed(.LEFT_BRACKET)
			{
				gmem.dbg_camera_offset_to_left -= global_grid_cell_size
			}
			else if rl.IsKeyPressed(.RIGHT_BRACKET)
			{
				gmem.dbg_camera_offset_to_left += global_grid_cell_size
			}

			if rl.IsKeyDown(.MINUS) && rl.IsKeyDown(.EQUAL)
			{
				gmem.dbg_camera_zoom = 1.0
			}
			else if rl.IsKeyPressed(.MINUS)
			{
				gmem.dbg_camera_zoom -= 0.1
			}
			else if rl.IsKeyPressed(.EQUAL)
			{
				gmem.dbg_camera_zoom += 0.1
			}
		}
		else if rl.IsKeyDown(level_mod_key)
		{
			if rl.IsKeyPressed(.RIGHT_BRACKET)
			{
				if gmem.level_index == 4
				{
					gmem.level_index = 0
				}
				else
				{
					gmem.level_index += 1
				}
			}
			else if rl.IsKeyPressed(.LEFT_BRACKET)
			{
				if gmem.level_index == 0
				{
					gmem.level_index = 4
				}
				else
				{
					gmem.level_index -= 1
				}
			}
		}
		else if rl.IsKeyDown(frogs_on_lilypad_mod_key)
		{
			if rl.IsKeyPressed(.RIGHT_BRACKET)
			{
				for &present in gmem.is_frogs_on_lilypads
				{
					if !present
					{
						present = true
						break
					}
				}
			}
		}
		else if rl.IsKeyPressed(.M)
		{
			root_state_main_menu_enter()
			return
		}
		else
		{
			skip_next_frame = rl.IsKeyPressed(.RIGHT)

			if rl.IsKeyDown(.LEFT_BRACKET) && rl.IsKeyDown(.RIGHT_BRACKET)
			{
				gmem.dbg_speed_multiplier = 5.0
			}
			else if rl.IsKeyDown(.LEFT_BRACKET)
			{
				gmem.dbg_speed_multiplier = 2.0
			}
			else if rl.IsKeyDown(.RIGHT_BRACKET)
			{
				gmem.dbg_speed_multiplier = 3.0
			}
			else
			{
				gmem.dbg_speed_multiplier = 1.0
			}

			if rl.IsKeyPressed(.T)
			{
				gmem.dbg_timer_lose_life_pause = !gmem.dbg_timer_lose_life_pause
			}			
		}
	}


	frame_time_uncapped := rl.GetFrameTime()
	frame_time := min(frame_time_uncapped, f32(1.0/60.0))


	frogger_anim_frames := [?]Sprite_Clip_Name{
		.Frogger_Frame_1, .Frogger_Frame_2, .Frogger_Frame_1, .Frogger_Frame_0,
	}


	river := rl.Rectangle{0, 3, 14, 5}
	riverbed := rl.Rectangle{0, 1, 14,2}

	should_run_simulation := true
	if gmem.pause && !skip_next_frame
	{
		should_run_simulation = false
	}

	if should_run_simulation
	{	

		can_frogger_request_move := timer_is_complete(gmem.frogger_move_lerp_timer)  && !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) && timer_is_complete(gmem.level_end_timer) && !gmem.pause && gmem.countdown_timer_game_over_display == 0
		if can_frogger_request_move  
		{
			frogger_move_direction := [2]f32{0,0}
			is_input_left := rl.IsKeyPressed(.LEFT) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_LEFT)
			is_input_right := rl.IsKeyPressed(.RIGHT) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_RIGHT)
			is_input_up := rl.IsKeyPressed(.UP) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_UP)
			is_input_down := rl.IsKeyPressed(.DOWN) || rl.IsGamepadButtonPressed(0, .LEFT_FACE_DOWN)

			if is_input_left
			{
				frogger_move_direction.x = -1
				gmem.frogger_sprite_rotation  = 270
			}
			else if is_input_right
			{
				frogger_move_direction.x = 1
				gmem.frogger_sprite_rotation = 90
			} 
			else if is_input_up
			{
				frogger_move_direction.y = -1
				gmem.frogger_sprite_rotation = 0
			} 
			else if is_input_down
			{
				frogger_move_direction.y = 1
				gmem.frogger_sprite_rotation = 180
			}

			did_frogger_request_move := frogger_move_direction != [2]f32{0,0}

			if did_frogger_request_move 
			{
				timer_start(&frogger_anim_timer)

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
					frogger_next_pos.x = 0

					if !(frogger_next_pos.x >= gmem.frogger_pos.x)
					{
						timer_start(&gmem.frogger_move_lerp_timer)
						gmem.frogger_move_lerp_start_pos = gmem.frogger_pos
						gmem.frogger_move_lerp_end_pos = frogger_next_pos
					}
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

		should_update_lily := !gmem.is_lily_on_frogger
		if should_update_lily 
		{ 
			entity_that_lily_is_on := entities[lily_logs_to_spawn_on[gmem.level_index]]

			lily_lerp_timer_just_completed := false
			if timer_is_playing(lily_lerp_timer)
			{
				lily_lerp_timer_just_completed = !timer_advance(&lily_lerp_timer, frame_time)
				t := timer_percentage(lily_lerp_timer)
				t = min(t, 1.0)
				lily_relative_log_pos_x = (1.0 - t) * lily_lerp_relative_log_start_x + t * lily_lerp_relative_log_end_x
			}

			if lily_lerp_timer_just_completed
			{
				timer_start(&lily_wait_timer)

				right_edge_of_log_x := entity_that_lily_is_on.rectangle.width - 1
				is_lily_on_right_edge_of_log := lily_relative_log_pos_x >= right_edge_of_log_x
				
				left_edge_of_log_x : f32 = 0
				is_lily_on_left_edge_of_log := lily_relative_log_pos_x <= left_edge_of_log_x	

				is_lily_on_edge_of_log :=  is_lily_on_right_edge_of_log || is_lily_on_left_edge_of_log
				if is_lily_on_edge_of_log
				{
					lily_direction = .Up
				}
			}

			lily_wait_timer_just_completed := false
			if timer_is_playing(lily_wait_timer)
			{
				lily_wait_timer_just_completed = !timer_advance(&lily_wait_timer, frame_time)
			}

			if lily_wait_timer_just_completed
			{
				move_amount_x := f32(0)

				right_edge_of_log_x := entity_that_lily_is_on.rectangle.width - 1
				is_lily_on_right_edge_of_log := lily_relative_log_pos_x >= right_edge_of_log_x
				
				left_edge_of_log_x : f32 = 0
				is_lily_on_left_edge_of_log := lily_relative_log_pos_x <= left_edge_of_log_x

				should_move_lily_right := lily_direction == .Right || is_lily_on_left_edge_of_log
				if should_move_lily_right
				{
					lily_direction = .Right
					move_amount_x = 1
				}

				should_move_lily_left := lily_direction == .Left || is_lily_on_right_edge_of_log
				if should_move_lily_left
				{
					lily_direction = .Left
					move_amount_x = -1
				}

				did_lily_move_amount_get_set := move_amount_x != 0

				if did_lily_move_amount_get_set
				{
					lily_lerp_relative_log_start_x = lily_relative_log_pos_x
					lily_lerp_relative_log_end_x = lily_lerp_relative_log_start_x + move_amount_x
					timer_start(&lily_lerp_timer)
				}
			}


		}	
		

		should_check_for_lily_frogger_collision := !gmem.is_lily_on_frogger
		if should_check_for_lily_frogger_collision
		{
			frogger_center_pos    := gmem.frogger_pos + 0.5
			entity_that_lily_is_on   := entities[lily_logs_to_spawn_on[gmem.level_index]]
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
		
		should_move_frogger := timer_is_playing(gmem.frogger_move_lerp_timer)
		if should_move_frogger 
		{
			timer_advance(&gmem.frogger_move_lerp_timer, frame_time)
			t := timer_percentage(gmem.frogger_move_lerp_timer)
			t = min(t, 1.0)
			gmem.frogger_pos.x = (1.0 - t) * gmem.frogger_move_lerp_start_pos.x + t * gmem.frogger_move_lerp_end_pos.x
			gmem.frogger_pos.y = (1.0 - t) * gmem.frogger_move_lerp_start_pos.y + t * gmem.frogger_move_lerp_end_pos.y
		}


		{ // update timers
			timer_advance(&frogger_anim_timer, frame_time)
			timer_advance(&gmem.timer_is_active_score_100, frame_time)
			timer_advance(&gmem.timer_is_active_score_200, frame_time)
			for &animation_player in animation_players
			{
				animation := animation_frames[animation_player.animation_name]
				animation_fps := animation_fps_list[animation_player.animation_name]
				animation_timer_advance(&animation_player.timer, len(animation), animation_fps, frame_time)
			}
		}


		{ // frogger death animation
			if animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer)
			{
				animation := animation_frames[animation_player_frogger_is_dying.animation_name]
				animation_fps := animation_fps_list[animation_player_frogger_is_dying.animation_name]
				animation_timer_advance(&gmem.animation_player_frogger_is_dying.timer, len(animation), animation_fps, frame_time)
				did_complete := animation_timer_is_complete(gmem.animation_player_frogger_is_dying.timer, len(animation), animation_fps)
				if did_complete && gmem.lives != 0
				{
					frogger_reset()
				}
				else if did_complete && gmem.lives == 0
				{
					frogger_reset()
					gmem.countdown_timer_game_over_display = global_countdown_timer_game_over_display
					// root_state_main_menu_enter()
					// return // don't process anything else here
					
				}
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
				for gmem.is_frogs_on_lilypads[fly_lilypad_indices[fly_lilypad_index]]
				{
					fly_lilypad_index += 1
					if fly_lilypad_index >= len(fly_lilypad_indices)
					{
						fly_lilypad_index = 0
					}
				}
			}
		}

		move_entities_and_wrap(entities, frame_time)

		should_process_moving_frogger_with_intersecting_entities := !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) 
		if should_process_moving_frogger_with_intersecting_entities
		{ 
			gmem.frogger_pos, gmem.frogger_move_lerp_end_pos = move_frogger_with_intersecting_entities(gmem.frogger_pos, gmem.frogger_move_lerp_end_pos, entities, frame_time)
		}

		{ // frogger get points for moving up
			point_value : int = 10
			should_award_points := gmem.frogger_pos.y <= gmem.score_frogger_max_y_tracker
			if should_award_points
			{
				gmem.score_frogger_max_y_tracker -= 1
				score_increment(point_value)
			}
		}

		{ // snakes
			for &snake, i in snakes
			{

				left_turnaround_boundary := -2
				right_turnaround_boundary := global_number_grid_cells_axis_x

				snake_world_rectangle := snake.rectangle

				entity_that_snake_is_on := entities[snake.snake_behavior.on_entity_id]

				if snake.snake_behavior.snake_mode == .On_Entity
				{
					snake_world_rectangle.x += entity_that_snake_is_on.rectangle.x
					snake_world_rectangle.y += entity_that_snake_is_on.rectangle.y
				}

				snake_is_beyond_right_side_of_screen := snake_world_rectangle.x > global_number_grid_cells_axis_x
				snake_is_beyond_left_side_of_screen := snake_world_rectangle.x <= -snake.rectangle.width

				median_y : f32 = 8
				frogger_is_on_or_below_median := gmem.frogger_pos.y >= median_y
			
				if snake.snake_behavior.snake_mode == .On_Median
				{
					snake.rectangle.x += snake.speed * frame_time * gmem.dbg_speed_multiplier
					entity_that_snake_is_on_is_offscreen_and_has_room_for_snake := entity_that_snake_is_on.rectangle.x < -snake.rectangle.width
					snake_is_offscreen := snake_is_beyond_left_side_of_screen || snake_is_beyond_right_side_of_screen

					should_switch_to_on_entity_mode := entity_that_snake_is_on_is_offscreen_and_has_room_for_snake && !frogger_is_on_or_below_median && snake_is_offscreen

					if should_switch_to_on_entity_mode
					{
						snake.speed = -snake.speed

						// TODO(jblat): Make this more of a "chance" or random, or based off of counter
						// switch mode
						snake.snake_behavior.snake_mode = .On_Entity
						snake.speed = 0.2
						snake.rectangle.x = 0
						snake.rectangle.y = 0
					}
					else
					{	snake_is_moving_left := snake.speed < 0
						should_turn_right := snake_is_moving_left && snake_is_beyond_left_side_of_screen
						if should_turn_right
						{
							snake.speed = -snake.speed
						}
						should_turn_left := !snake_is_moving_left && snake_is_beyond_right_side_of_screen
						if should_turn_left
						{
							snake.speed = -snake.speed
						}
					}
				}
				else if snake.snake_behavior.snake_mode == .On_Entity
				{
					

					rel_left_turnaround_boundary : f32 = 0
					rel_right_turnaround_boundary : f32 = entity_that_snake_is_on.rectangle.width - 2

					snake.rectangle.x += snake.speed * frame_time * gmem.dbg_speed_multiplier
					if snake.rectangle.x > rel_right_turnaround_boundary
					{
						snake.speed = -snake.speed
					}
					else if snake.rectangle.x < rel_left_turnaround_boundary
					{
						snake.speed = -snake.speed
					}					
					
					should_switch_to_snake_median_mode := frogger_is_on_or_below_median && snake_is_beyond_right_side_of_screen
					if should_switch_to_snake_median_mode
					{
						snake.snake_behavior.snake_mode = .On_Median
						frogger_is_closer_to_left_side_of_screen := gmem.frogger_pos.x <= global_number_grid_cells_axis_x / 2
						snake.rectangle.y = median_y
						if frogger_is_closer_to_left_side_of_screen
						{
							snake.rectangle.x = -snake.rectangle.width
							snake.speed = 1
						}
						else
						{	
							snake.rectangle.x = global_number_grid_cells_axis_x + snake.rectangle.width
							snake.speed = -1
						}
					} 

				}

			}
		}

		should_process_crocodile_timers := gmem.level_index != 0
		if should_process_crocodile_timers 
		{
			if timer_is_playing(timer_crocodile_inactive)
			{
				just_completed := !timer_advance(&timer_crocodile_inactive, frame_time)
				if just_completed
				{
					timer_start(&timer_crocodile_peek)
				}
			}
			else if timer_is_playing(timer_crocodile_peek)
			{
				just_completed := !timer_advance(&timer_crocodile_peek, frame_time)
				if just_completed
				{
					timer_start(&timer_crocodile_attack)
				}
			}
			else if timer_is_playing(timer_crocodile_attack)
			{
				just_completed := !timer_advance(&timer_crocodile_attack, frame_time)
				if just_completed
				{
					timer_start(&timer_crocodile_inactive)
					current_crocodile_lilypad_id_index += 1
					should_wrap_index := current_crocodile_lilypad_id_index >= len(lilypad_ids_crocodile)
					if should_wrap_index
					{
						current_crocodile_lilypad_id_index = 0
					}
				}
			}
		}
		else
		{
			timer_stop(&timer_crocodile_peek)
			timer_stop(&timer_crocodile_attack)
			timer_start(&timer_crocodile_inactive)
		}

		{ // otters
			for &otter in otters
			{
				just_finished_attacking := false
				if timer_is_playing(otter.timer_attack)
				{
					just_finished_attacking = !timer_advance(&otter.timer_attack, frame_time)
				}
				// place otters if they intersect with a entity
				is_otter_intersecting_with_any_entities := false
				intersecting_entity := Entity {}
				for entity in entities
				{
					is_otter_intersecting_with_any_entities = is_otter_intersecting_with_any_entities || rl.CheckCollisionRecs(otter.entity.rectangle, entity.rectangle)
					intersecting_entity := entity
				}

				frogger_rectangle := rl.Rectangle { gmem.frogger_pos.x - 0.2 , gmem.frogger_pos.y, 1.4, 1}

				is_otter_intersecting_with_frogger := rl.CheckCollisionRecs(otter.entity.rectangle, frogger_rectangle)

				should_otter_kill_frogger := is_otter_intersecting_with_frogger && !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) && !gmem.dbg_is_frogger_unkillable
				if should_otter_kill_frogger
				{
					entity_intersecting_with_frogger := Entity {}
					for entity in entities
					{
						frogger_center_pos := gmem.frogger_pos + 0.5
						is_frogger_intersecting_with_entity := rl.CheckCollisionPointRec(frogger_center_pos, entity.rectangle)
						if is_frogger_intersecting_with_entity
						{
							entity_intersecting_with_frogger = entity
						}
					}
					otter.entity.speed = entity_intersecting_with_frogger.speed
					timer_start(&otter.timer_attack)
					frogger_start_dying(.Frogger_Dying_Hit)
				}

				is_otter_out_of_left_bounds := otter.entity.speed < 0 && otter.entity.rectangle.x < -otter.entity.rectangle.width
				is_otter_out_of_right_bounds := otter.entity.speed > 0 && otter.entity.rectangle.x > global_number_grid_cells_axis_x + 1

				is_otter_out_of_bounds := is_otter_out_of_left_bounds || is_otter_out_of_right_bounds

				should_respawn_otter := ( ( is_otter_out_of_bounds || is_otter_intersecting_with_any_entities ) && !timer_is_playing(otter.timer_attack) ) || just_finished_attacking

				if should_respawn_otter 
				{
					spawn_data := otter_spawn_descriptions[current_otter_spawn_data_id]
					otter.entity.rectangle.x = spawn_data.pos.x
					otter.entity.rectangle.y = spawn_data.pos.y
					otter.entity.speed = spawn_data.speed

					current_otter_spawn_data_id += 1
					should_wrap := current_otter_spawn_data_id >= len(otter_spawn_descriptions)
					if should_wrap
					{
						current_otter_spawn_data_id = 0
					}
				}

				otter.entity.rectangle.x += otter.entity.speed * frame_time * gmem.dbg_speed_multiplier


			}
		}

		should_check_pre_win_condition_frogger_is_killed := !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer)  && !gmem.dbg_is_frogger_unkillable
		if should_check_pre_win_condition_frogger_is_killed
		{
			{ // crocodile attack
				if timer_is_playing(timer_crocodile_attack)
				{
					lilypad_id_crocodile_is_in := lilypad_ids_crocodile[current_crocodile_lilypad_id_index]
					lilypad := lilypads[lilypad_id_crocodile_is_in]
					frogger_center_pos := gmem.frogger_pos + 0.5
					frogger_in_crocodile_mouth := rl.CheckCollisionPointRec(frogger_center_pos, lilypad)
					if frogger_in_crocodile_mouth
					{
						frogger_start_dying(.Frogger_Dying_Hit)
					}
				}
			}
		}


		should_check_for_win_condtions := !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) && !timer_is_playing(gmem.level_end_timer)
		if should_check_for_win_condtions 
		{
			for lilypad, i in lilypads 
			{	
				frogger_center_pos := gmem.frogger_pos + 0.5
				is_frogger_on_lilypad := rl.CheckCollisionPointRec(frogger_center_pos, lilypad)
				is_there_already_a_frog_here := gmem.is_frogs_on_lilypads[i]
				did_get_frogger_home := is_frogger_on_lilypad && !is_there_already_a_frog_here
				
				if did_get_frogger_home 
				{
					gmem.is_frogs_on_lilypads[i] = true

					// NOTE(jblat): The extra 10 is essentially to give the effect of getting the 10 points from advancing a tile
					// 10 = frog safely gets gome
					score_amount_get_frogger_home := 60
					score_increment(score_amount_get_frogger_home)
					

					did_frogger_get_fly := fly_lilypad_indices[fly_lilypad_index] == i && fly_is_active
					if did_frogger_get_fly
					{
						score_amount_frogger_get_fly := 200
						score_increment(score_amount_frogger_get_fly)
						timer_start(&gmem.timer_is_active_score_200)
						gmem.pos_score_200.x = lilypad.x
						gmem.pos_score_200.y = lilypad.y - 1
					}

					if gmem.is_lily_on_frogger
					{
						score_amount_get_lily_home := 200
						score_increment(score_amount_get_lily_home)
						timer_start(&gmem.timer_is_active_score_200)
						gmem.pos_score_200.x = lilypad.x
						gmem.pos_score_200.y = lilypad.y - 1
					}

					gmem.countdown_timer_display_last_cycle_completion = global_countdown_timer_duration_display_last_cycle_completion

					// so i think frogger counts two ticks for every second? based on timing an emulated version
					remaining_seconds := int(gmem.countdown_timer_lose_life) * 2
					time_bonus : int = 10 * remaining_seconds
					score_increment(time_bonus)

					gmem.last_cycle_completion_in_seconds = i32(remaining_seconds)
					frogger_reset()
				}
			}

			number_of_frogs_on_lilypad := 0
			for present in gmem.is_frogs_on_lilypads
			{
				if present
				{
					number_of_frogs_on_lilypad += 1
				}
			}

			is_all_frogs_on_lilypads := number_of_frogs_on_lilypad == len(gmem.is_frogs_on_lilypads)
			if is_all_frogs_on_lilypads
			{
				// 1000 for saving all frogs
				score_increment(1000)
				timer_start(&gmem.level_end_timer)
				// TODO(jalfonso): eventually i think this level stuff will be calculated by modulo
				gmem.level_index += 1
				if gmem.level_index > 4
				{
					gmem.level_index = 0
				}
			}
		}


		if timer_is_playing(gmem.level_end_timer)
		{
			timer_advance(&gmem.level_end_timer, frame_time)
			if timer_is_complete(gmem.level_end_timer)
			{
				for &present in gmem.is_frogs_on_lilypads
				{
					present = false
				}
			}
		}

		should_process_countdown_timer := !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) && !gmem.dbg_timer_lose_life_pause && gmem.countdown_timer_game_over_display == 0 && !timer_is_playing(gmem.level_end_timer)
		if should_process_countdown_timer
		{
			gmem.countdown_timer_lose_life -= frame_time
			gmem.countdown_timer_lose_life = max(0.0, gmem.countdown_timer_lose_life)
		}

		gmem.countdown_timer_display_last_cycle_completion -= frame_time
		gmem.countdown_timer_display_last_cycle_completion = max(0.0, gmem.countdown_timer_display_last_cycle_completion)

		if gmem.countdown_timer_game_over_display > 0.0
		{
			gmem.countdown_timer_game_over_display -= frame_time
			gmem.countdown_timer_game_over_display = max(0.0, gmem.countdown_timer_game_over_display)
			just_completed := gmem.countdown_timer_game_over_display == 0.0
			if just_completed
			{
				root_state_main_menu_enter()
				return // don't process anything else here	
			}
		}

		
		should_check_for_frogger_is_killed := !animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer)  && !gmem.dbg_is_frogger_unkillable
		if should_check_for_frogger_is_killed 
		{
			is_frogger_out_of_bounds := gmem.frogger_pos.x + 0.5 < 0 || gmem.frogger_pos.x - 0.5 >= global_number_grid_cells_axis_x -1 || gmem.frogger_pos.y < 0 || gmem.frogger_pos.y > global_number_grid_cells_axis_y
			if is_frogger_out_of_bounds 
			{
				frogger_start_dying(.Frogger_Dying_Drown)
			}

			frogger_center_pos := gmem.frogger_pos + 0.5
			for entity in entities
			{
				is_frogger_intersecting_entity := rl.CheckCollisionPointRec(frogger_center_pos, entity.rectangle)
				can_entity_kill_frogger := entity.collision_behavior == .Kill_Frogger
				is_frogger_hit_by_entity := is_frogger_intersecting_entity && can_entity_kill_frogger

				if is_frogger_hit_by_entity
				{
					frogger_start_dying(.Frogger_Dying_Hit)
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
				is_frog_already_here := gmem.is_frogs_on_lilypads[i]
				is_frogger_on_one_of_the_open_lilypads = is_frogger_on_one_of_the_open_lilypads || (is_frogger_on_lilypad && !is_frog_already_here)
			}

			did_frogger_collide_with_riverbed := is_frogger_in_riverbed && !is_frogger_on_one_of_the_open_lilypads

			if did_frogger_collide_with_riverbed
			{
				frogger_start_dying(.Frogger_Dying_Drown)
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

			for entity in entities
			{
				#partial switch sd in entity.sprite_data
				{
					case Animation_Player_Name:
					{
						animation_player_name := sd
						animation_player := animation_players[animation_player_name]
						animation_fps := animation_fps_list[animation_player.animation_name]

						clip := animation_get_frame_sprite_clip_id(animation_player.timer.t, animation_fps, animation_frames[animation_player.animation_name])

						if animation_player.animation_name == .Alligator
						{
							// clip := animation_get_frame_sprite_clip_id(animation_player.timer.t, animation_fps, animation_frames[animation_player.animation_name])
							if clip == .Alligator_Mouth_Open
							{
								hit_box := alligator_hit_box_relative_mouth_open
								hit_box.x += entity.rectangle.x
								hit_box.y += entity.rectangle.y

								frogger_center_pos := gmem.frogger_pos + 0.5
								did_frogger_collide_with_hitbox := rl.CheckCollisionPointRec(frogger_center_pos, hit_box)
								if did_frogger_collide_with_hitbox
								{
									frogger_start_dying(.Frogger_Dying_Hit)
								}
							}
						}
						else if animation_player.animation_name == .Diving_Turtle
						{
							is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos,  entity.rectangle)
							// clip := animation_get_frame_sprite_clip_id(animation_timers[sd].t, animation_fps_list[animation_id], animation_frames[animation_id])
							diving_turtles_underwater_clip_id := Sprite_Clip_Name.Empty
							is_turtle_underwater := clip == diving_turtles_underwater_clip_id
							
							should_frogger_drown := is_frogger_center_pos_inside_turtle_rectangle && is_turtle_underwater
							if should_frogger_drown
							{
								is_frogger_on_safe_entity = false
							}
						}
					}
				}
				
			}

			did_frogger_fall_in_river := !is_frogger_on_safe_entity && is_frogger_in_river_region

			if did_frogger_fall_in_river
			{
				frogger_start_dying(.Frogger_Dying_Drown)
			}

			{ // snake kill
				for snake, i in snakes
				{
					snake_relative_hitbox := rl.Rectangle{0, 0, 1, 1}
					if snake.speed > 0
					{
						// flipped
						snake_relative_hitbox = rl.Rectangle{1, 0, 1, 1}
					}

					snake_world_hitbox := snake_relative_hitbox
					snake_world_hitbox.x += snake.rectangle.x
					snake_world_hitbox.y += snake.rectangle.y

					if snake.snake_behavior.snake_mode == .On_Entity
					{
						parent_rectangle := entities[snake.snake_behavior.on_entity_id].rectangle
						snake_world_hitbox.x += parent_rectangle.x
						snake_world_hitbox.y += parent_rectangle.y
					}

					is_frogger_intersecting_snake_hitbox := rl.CheckCollisionPointRec(frogger_center_pos, snake_world_hitbox)

					if is_frogger_intersecting_snake_hitbox
					{
						frogger_start_dying(.Frogger_Dying_Hit)
					}
				}
			}

			{ // countdown timer
				is_countdown_complete := gmem.countdown_timer_lose_life <= 0.0 
				if is_countdown_complete
				{
					frogger_start_dying(.Frogger_Dying_Hit)
				}
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

		if rl.IsKeyPressed(.F4)
		{
			gmem.dbg_show_level = !gmem.dbg_show_level
		}

	}


	// NOTE(jblat): For mouse, see: https://github.com/raysan5/raylib/blob/master/examples/core/core_window_letterbox.c

	{ // DRAW TO RENDER TEXTURE
		camera := rl.Camera2D {
			offset = [2]f32{gmem.dbg_camera_offset_to_left, 0},
			target = [2]f32{0,0},
			rotation = 0,
			zoom = gmem.dbg_camera_zoom,
		}

		rl.BeginTextureMode(gmem.game_render_target)

		rl.BeginMode2D(camera)

		rl.ClearBackground(rl.LIGHTGRAY) 


		{ // draw background
			scale : f32 =  global_grid_cell_size / global_sprite_sheet_cell_size
			rl.DrawTextureEx(gmem.texture_background, [2]f32{0,0}, 0, scale, rl.WHITE)
		}

		should_display_last_cycle_time := gmem.countdown_timer_display_last_cycle_completion > 0.0
		if should_display_last_cycle_time 
		{ 
			text := fmt.ctprint("TIME:", gmem.last_cycle_completion_in_seconds)
			size : f32= 0.7
			text_dimensions := rl.MeasureTextEx(gmem.font, text, size, 0)
			center_screen_on_median := [2]f32{global_number_grid_cells_axis_x / 2, 8.15}
			leftmost_x := center_screen_on_median.x - text_dimensions.x/2
			r := rl.Rectangle{leftmost_x, 8.15, text_dimensions.x, size}
			rlgrid.draw_rectangle_on_grid(r, rl.BLACK, global_grid_cell_size)
			rlgrid.draw_text_on_grid_centered(gmem.font, text, center_screen_on_median, size, 0, rl.RED, global_grid_cell_size)
		}

		should_display_game_over := gmem.countdown_timer_game_over_display > 0.0
		if should_display_game_over 
		{ 
			text : cstring = "GAME OVER"
			size : f32= 0.7
			text_dimensions := rl.MeasureTextEx(gmem.font, text, size, 0)
			center_screen_on_median := [2]f32{global_number_grid_cells_axis_x / 2, 8.15}
			leftmost_x := center_screen_on_median.x - text_dimensions.x/2
			r := rl.Rectangle{leftmost_x, 8.15, text_dimensions.x, size}
			rlgrid.draw_rectangle_on_grid(r, rl.BLACK, global_grid_cell_size)
			rlgrid.draw_text_on_grid_centered(gmem.font, text, center_screen_on_median, size, 0, rl.RED, global_grid_cell_size)
		}


		{ // draw entities
			for entity, i in entities 
			{
				switch sd in entity.sprite_data
				{
					case Sprite_Clip_Name:
					{
						draw_sprite_sheet_clip_on_grid(sd, entity.rectangle, global_grid_cell_size, 0)
					}
					case Animation_Player_Name:
					{
						animation_player_id := sd
						animation_player := animation_players[sd]
						animation_fps := animation_fps_list[animation_player.animation_name]
						clip := animation_get_frame_sprite_clip_id(animation_player.timer.t, animation_fps, animation_frames[animation_player.animation_name])
						draw_sprite_sheet_clip_on_grid(clip, entity.rectangle, global_grid_cell_size, 0)
					}
				}
			}
		}

		{ // draw snakes
			for snake, i in snakes
			{
				#partial switch sd in snake.sprite_data
				{
					case Animation_Player_Name:
					{
						r := snake.rectangle
						if snake.snake_behavior.snake_mode == .On_Entity
						{
							parent_entity_rectangle := entities[snake.snake_behavior.on_entity_id].rectangle
							r.x += parent_entity_rectangle.x
							r.y += parent_entity_rectangle.y
						}
						flip_x := false
						if snake.speed > 0
						{
							flip_x = true
						}
						animation_player := animation_players[sd]
						clip := animation_get_frame_sprite_clip_id(animation_player.timer.t, animation_player.fps, animation_frames[animation_player.animation_name])
						draw_sprite_sheet_clip_on_grid(clip, r, global_grid_cell_size, 0, flip_x, false)						
					}
				}
			}
		}

		{ // draw crocodile
			lilypad_rectangle := lilypads[lilypad_ids_crocodile[current_crocodile_lilypad_id_index]] 
			is_frog_here := gmem.is_frogs_on_lilypads[lilypad_ids_crocodile[current_crocodile_lilypad_id_index]]

			if timer_is_playing(timer_crocodile_peek) && !is_frog_here
			{
				draw_sprite_sheet_clip_on_grid(.Crocodile_Head_Peek, lilypad_rectangle, global_grid_cell_size, 0)
			}
			else if timer_is_playing(timer_crocodile_attack) && !is_frog_here
			{
				draw_sprite_sheet_clip_on_grid(.Crocodile_Head_Attack, lilypad_rectangle, global_grid_cell_size, 0)
			}
		}

		{ // draw otters
			for otter in otters
			{
				flip_x := false
				if otter.entity.speed < 0
				{
					flip_x = true
				}
				if timer_is_playing(otter.timer_attack)
				{
					draw_sprite_sheet_clip_on_grid(.Otter_Attacking, otter.entity.rectangle, global_grid_cell_size, 0, flip_x, false)
				}
				else
				{
					draw_sprite_sheet_clip_on_grid(.Otter_Peek, otter.entity.rectangle, global_grid_cell_size, 0, flip_x, false)
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
			progress_of_level_end_timer := timer_percentage(gmem.level_end_timer)

			for lp, i in lilypads
			{	
				is_there_a_frog_on_this_lilypad := gmem.is_frogs_on_lilypads[i]
				if is_there_a_frog_on_this_lilypad
				{
					frog_p : f32 = f32(i) / f32(len(lilypads))
					if progress_of_level_end_timer == 1
					{
						rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, global_sprite_sheet_clips[.Happy_Frog_Closed_Mouth], global_sprite_sheet_cell_size,  lp, global_grid_cell_size, 0)
					}
					else
					{
						if frog_p >= progress_of_level_end_timer
						{
							rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, global_sprite_sheet_clips[.Happy_Frog_Closed_Mouth], global_sprite_sheet_cell_size,  lp, global_grid_cell_size, 0)
						}
						else
						{
							rlgrid.draw_grid_texture_clip_on_grid(gmem.texture_sprite_sheet, global_sprite_sheet_clips[.Happy_Frog_Open_Mouth], global_sprite_sheet_cell_size,  lp, global_grid_cell_size, 0)
						}
					}
				}
			}
		}

		is_game_over := gmem.countdown_timer_game_over_display > 0 
		if !is_game_over 
		{ // draw frogger
			anim_timer    : f32 =    animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) ? gmem.animation_player_frogger_is_dying.timer.t     : frogger_anim_timer.amount
			anim_fps      : f32 =    animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) ? animation_fps_list[gmem.animation_player_frogger_is_dying.animation_name]       : 12.0 
			frames :[]Sprite_Clip_Name = animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) ? animation_frames[gmem.animation_player_frogger_is_dying.animation_name ] : frogger_anim_frames[:]
			rotation : f32         = animation_timer_is_playing(gmem.animation_player_frogger_is_dying.timer) ? 0                            : gmem.frogger_sprite_rotation
			
			clip := animation_get_frame_sprite_clip_id(anim_timer, anim_fps, frames)
			rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}

			draw_sprite_sheet_clip_on_grid(clip, rectangle, global_grid_cell_size, rotation)
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
				log_that_lily_is_on := lily_logs_to_spawn_on[gmem.level_index]
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

		{ // lives
			for i in 0 ..< gmem.lives
			{
				scale : f32 = 0.7

				dst_rectangle := rl.Rectangle{f32(i) * scale, global_number_grid_cells_axis_y - 1, 1, 1}
				dst_rectangle.width *= scale
				dst_rectangle.height *= scale
				draw_sprite_sheet_clip_on_grid(.Frogger_Frame_0, dst_rectangle, global_grid_cell_size, 0.0)

			}
		}

		
	
		if gmem.dbg_show_grid 
		{ 	
			for x : f32 = -camera.offset.x; x < global_number_grid_cells_axis_x; x += 1 
			{
				render_x := x * global_grid_cell_size
				render_start_y : f32 = 0
				render_end_y := global_game_view_pixels_height
				rl.DrawLineV([2]f32{render_x, render_start_y}, [2]f32{render_x, render_end_y}, rl.WHITE)
			}

			for y : f32 = 0; y < global_number_grid_cells_axis_y; y += 1 
			{
				render_y := y * global_grid_cell_size
				render_start_x : f32 = -camera.offset.x
				render_end_x := global_game_view_pixels_width
				rl.DrawLineV([2]f32{render_start_x, render_y}, [2]f32{render_end_x, render_y}, rl.WHITE)
			}
		}

		
		if gmem.dbg_show_entity_bounding_rectangles
		{	
			frogger_rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}
			rlgrid.draw_rectangle_lines_on_grid(frogger_rectangle, 4, rl.GREEN, global_grid_cell_size)
		}

		if gmem.dbg_show_level
		{
			text_level := fmt.ctprintf("level: %d", gmem.level_index + 1)
			text_pos_level := [2]f32 {1, 8}
			rlgrid.draw_text_on_grid(gmem.font, text_level, text_pos_level, 0.7, 0, rl.WHITE, global_grid_cell_size)
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
		}

		{ // countdown timer
			max_rectangle_width : f32 = 7.5
			percentage_full := gmem.countdown_timer_lose_life / global_countdown_timer_lose_life_duration
			rectangle_width := max_rectangle_width * percentage_full

			timer_rectangle := rl.Rectangle { global_number_grid_cells_axis_x - 2, global_number_grid_cells_axis_y - 0.5, rectangle_width, 0.5 }
			color := rl.GREEN
			if percentage_full < 0.2
			{
				color = rl.RED
			}
			rlgrid.draw_rectangle_on_grid_right_justified(timer_rectangle, color, global_grid_cell_size)
		}

		rl.EndMode2D()

		rl.EndTextureMode()
	}
}


root_state_main_menu :: proc()
{
	is_input_start := rl.IsKeyPressed(.ENTER) || rl.IsGamepadButtonPressed(0, .MIDDLE) || rl.IsGamepadButtonPressed(0, .MIDDLE_LEFT) || rl.IsGamepadButtonPressed(0, .MIDDLE_RIGHT) || rl.IsGamepadButtonPressed(0, .RIGHT_FACE_DOWN)  
	if is_input_start
	{
		gmem.countdown_timer_display_last_cycle_completion = 0
		gmem.lives = 3
		gmem.root_state = .Game
		gmem.animation_player_frogger_is_dying.timer.playing = false
		frogger_reset()
	}
	rl.BeginTextureMode(gmem.game_render_target)
	defer rl.EndTextureMode()

	rl.ClearBackground(rl.BLACK)
	title_centered_pos := [2]f32{global_number_grid_cells_axis_x / 2, 2}
	rlgrid.draw_text_on_grid_centered(gmem.font, "FROGGER", title_centered_pos, 2, 0, rl.GREEN, global_grid_cell_size )
	title_centered_pos.y += 2
	// rlgrid.draw_text_on_grid_centered(gmem.font, "PRO", title_centered_pos, 2, 0, rl.GREEN, global_grid_cell_size )

	press_enter_centered_pos := [2]f32{global_number_grid_cells_axis_x / 2, 8}
	rlgrid.draw_text_on_grid_centered(gmem.font, "press enter to play", press_enter_centered_pos, 0.7, 0, rl.WHITE, global_grid_cell_size)

	credits_centered_pos := [2]f32{global_number_grid_cells_axis_x / 2, global_number_grid_cells_axis_y - 3}
	rlgrid.draw_text_on_grid_centered(gmem.font, "a fanmade frogger remake", credits_centered_pos, 0.3, 0, rl.WHITE, global_grid_cell_size)

	credits_centered_pos.y += 0.3
	// rlgrid.draw_text_on_grid_centered(gmem.font, "code by john blat", credits_centered_pos, 0.3, 0, rl.WHITE, global_grid_cell_size)

}



@(export)
game_update :: proc()
{
	switch gmem.root_state
	{
		case .Main_Menu: root_state_main_menu()
		case .Game: root_state_game()
	}


	// rendering

	screen_width := f32(rl.GetScreenWidth())
	screen_height := f32(rl.GetScreenHeight())

	{ // DRAW TO WINDOW

		rl.BeginDrawing()
		// rl.BeginShaderMode(gmem.shader_pixel_filter)
		// rl.BeginBlendMode(.ALPHA_PREMULTIPLY)
		rl.ClearBackground(rl.BLACK)

		src := rl.Rectangle{ 0, 0, f32(gmem.game_render_target.texture.width), f32(-gmem.game_render_target.texture.height) }
		
		scale := min(screen_width/global_game_view_pixels_width, screen_height/global_game_view_pixels_height)

		window_scaled_width  := global_game_view_pixels_width * scale
		window_scaled_height := global_game_view_pixels_height * scale

		dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}
		rl.DrawTexturePro(gmem.game_render_target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)

		// rl.EndShaderMode()
		// rl.EndBlendMode()
		rl.EndDrawing()

	}

	free_all(context.temp_allocator)
}

@(export)
game_shutdown :: proc()
{
	when ODIN_OS != .JS { // no need to save this in web

		window_pos    := rl.GetWindowPosition()
		screen_width  := rl.GetScreenWidth()
		screen_height := rl.GetScreenHeight()

		window_save_data := Window_Save_Data {i32(window_pos.x), i32(window_pos.y), screen_width, screen_height}
		bytes_window_save_data := mem.ptr_to_bytes(&window_save_data)

		ok := write_entire_file(global_filename_window_save_data, bytes_window_save_data)
		if !ok
		{
			fmt.printfln("Error opening/creating Window Save Data File")
		}
		// file_window_save_data, err := os2.open(global_filename_window_save_data, {.Write, .Create})
		// if err != nil
		// {
		// 	fmt.printfln("Error opening/creating Window Save Data File: %v", err)
		// }
		// n_bytes_written, write_err := os2.write(file_window_save_data, bytes_window_save_data)
		// if write_err != nil
		// {
		// 	fmt.printfln("Error saving Window Save Data: %v", write_err)
		// }
		// did_not_write_all_bytes :=  n_bytes_written != size_of(window_save_data)
		// if did_not_write_all_bytes
		// {
		// 	fmt.printfln("Error saving Window Save Data: number bytes written = %v, number bytes expected = %v", n_bytes_written, size_of(window_save_data))
		// }
	}
}


should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return true
}


// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h))
}