package game

import "core:math"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:c"

import pirc "../pirc"
import shape "../shape"
// import rlgrid "../rlgrid"



global_game_texture_grid_cell_size : f32 : 64
global_number_grid_cells_axis_x    : f32 : 14
global_number_grid_cells_axis_y    : f32 : 16
game_resolution_width      : f32 : global_game_texture_grid_cell_size * global_number_grid_cells_axis_x
game_resolution_height     : f32 : global_game_texture_grid_cell_size * global_number_grid_cells_axis_y
global_countdown_timer_lose_life_duration : f32 = 30.0
global_level_end_timer_duration : f32 = 6.0


GREEN :: [4]u8 { 0, 255, 0, 255 }
RED :: [4]u8 { 255, 0, 0, 255 }
BLACK :: [4]u8 { 0, 0, 0, 255 }

Direction :: enum {
	Up, Down, Left, Right
}


Texture_Load_Description :: struct
{
   	tex_id : Texture_Id,
	name : string,
	png_data : []byte,
}

Font_Load_Description :: struct
{
	font_id : Font_Id,
	name : string,
	font_data : []byte,
}


Texture_Id :: enum pirc.Texture_Id
{
	Background,
	Sprite_Sheet,
}

Font_Id :: enum pirc.Font_Id
{
	Joystix,
}


Packed_Char :: struct
{
	x0, y0, x1, y1:       u16, // rectangle
	xoff, yoff, xadvance: f32, // glyph info
	xoff2, yoff2:         f32,
}

Font :: struct
{
	base_size : int,
	packed_chars : [96]Packed_Char,
}

Sprite_Data :: union {
	Sprite_Clip_Name,
	Animation_Player_Name,
}


Collision_Behavior :: enum {
	Move_Frogger,
	Kill_Frogger,
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


Entity_Behavior :: enum {
	Row_Obstacle,
	Snake,
	Otter,
	Alligator,
}


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


Entity :: struct
{
	rectangle : shape.Rectangle, // what is the hitbox? and where should we draw the entity?
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


Row :: struct {
	start_x: f32,
	speed: f32,
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


Main_Menu_State :: struct
{
	visible : bool,
}


Camera :: struct
{
	offset : [2]f32,
	target : [2]f32,
	zoom : f32,
}




G_State :: struct 
{	
	dt : f32, 

	root_state : Root_State,

	input_state : Input_State,

	// Spritesheets
	textures : [Texture_Id]pirc.Texture,
	// texture_sprite_sheet : pirc.Texture,
	// texture_background   : pirc.Texture,
	fonts : [Font_Id]Font,
	speed_multiplier_difficulty: f32,

	// Font
	font : pirc.Font_Id,

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


	level_current : int,

	// frogger
	frogger_pos       : [2]f32,
	frogger_move_lerp : Lerp_Position,

	frogger_sprite_rotation: f32,

	is_lily_on_frogger : bool,

	// win
	is_frog_present_on_lilypads :[5]bool,

	// score
	score :int,
	score_frogger_max_y_tracker : f32,

	// countdown timers
	timer_is_active_score_100: f32,
	timer_is_active_score_200: f32,
	countdown_timer_display_last_cycle_completion: f32,
	countdown_timer_game_over_display: f32,
	countdown_timer_lose_life: f32,
	level_end_timer :f32,



	pos_score_100: [2]f32,
	pos_score_200: [2]f32,

	pause : bool,

	lives: u32,
	counter_cycle: int,
	counter_level: int,


	level_index: u32,

	last_cycle_completion_in_seconds : i32,

	render_cmds : [dynamic]pirc.Cmd,

	camera : Camera,

	main_menu_state : Main_Menu_State,

}


texture_load_descriptions := [?] Texture_Load_Description {
	{ tex_id = .Background, name = "retro arcade background", png_data = #load("../../assets/frogger_background_modified.png") },
	{ tex_id = .Sprite_Sheet, name = "retro arcade sprites", png_data = #load("../../assets/frogger_sprite_sheet_modified.png") },
}

font_load_descriptions := [?] Font_Load_Description {
	{ font_id = .Joystix, name = "joystix", font_data = #load("../../assets/joystix monospace.otf")}
}



g_state: ^G_State


lilypads := [5]shape.Rectangle{
	{.5,   2, 1, 1},
	{3.5,  2, 1, 1},
	{6.5,  2, 1, 1},
	{9.5,  2, 1, 1},
	{12.5, 2, 1, 1},
}


measure_text :: proc(text: string, font: Font) -> [2]f32 
{
	result: [2]f32 = {0, cast(f32)font.base_size}
	width: f32 = 0.0

	for c in text 
	{
		if c < ' ' || c > '~' 
		{
			continue // skip unsupported chars
		}

		index := cast(int)(c - ' ')
		glyph := font.packed_chars[index]
		width += glyph.xadvance
	}

	result.x = width
	return result
}


check_collision_point_rectangle :: proc(point : [2]f32, rec : shape.Rectangle) -> bool
{

    collision := false

    if (point.x >= rec.x) && (point.x < (rec.x + rec.w)) && (point.y >= rec.y) && (point.y < (rec.y + rec.h))
    {
    	collision = true	
    }

    return collision
}



check_collision_rectangles :: proc(rec1 : shape.Rectangle, rec2 : shape.Rectangle) -> bool
{
	collision := false

   if ((rec1.x < (rec2.x + rec2.w) && (rec1.x + rec1.w) > rec2.x) &&
       (rec1.y < (rec2.y + rec2.h) && (rec1.y + rec1.h) > rec2.y)) 
	{
   		collision = true
	}

   return collision;
}

@(export)
game_memory_size :: proc() -> int
{
	return size_of(g_state)
}


@(export)
game_memory_ptr :: proc() -> rawptr
{
	return g_state
}



entity_move :: proc(entity: ^Entity, move_amount_x, dt: f32)
{
	entity.rectangle.x += move_amount_x * dt * g_state.dbg_speed_multiplier * g_state.speed_multiplier_difficulty
}




animation_frames_alligator := [?]Sprite_Clip_Name{ .Alligator_Mouth_Closed, .Alligator_Mouth_Open }
alligator_hit_box_relative_mouth_open := shape.Rectangle{2, 0, 1, 1}


animation_frames_regular_turtles := [?]Sprite_Clip_Name{ .Turtle_Frame_0, .Turtle_Frame_1, .Turtle_Frame_2 }
animation_frames_diving_turtles := [?]Sprite_Clip_Name{
	.Turtle_Frame_0, .Turtle_Frame_1, .Turtle_Frame_2, .Turtle_Frame_3, .Turtle_Frame_4, .Empty, .Turtle_Frame_4, .Turtle_Frame_3, 
}

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


global_sprite_animations := [Animation_Name][]Sprite_Clip_Name {
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

lily_is_active : bool = false
lily_sprite_sheet_clip := shape.Rectangle {2, 1, 1, 1}
lily_relative_log_pos_x : f32 = 0
lily_width : f32 = 1
lily_height : f32 = 1

lily_wait_timer := Timer {
	amount   = 0,
	duration = 1,
}

lily_direction : Direction = .Right

lily_move_lerp := Lerp_Value { timer = { amount = 0.2, duration = 0.2 } }

lily_logs_to_spawn_on := [?]int{15, 17, 14, 12, 11}

lilypad_ids_crocodile := [?]int{4, 0, 3, 1, 2, 1, 3, 0}
current_crocodile_lilypad_id_index := 0

timer_crocodile_inactive: f32
timer_crocodile_peek: f32
timer_crocodile_attack: f32


move_entities_and_wrap :: proc(entities: []Entity, dt: f32)
{
	for &entity in entities
	{
		rectangle := &entity.rectangle
		rectangle_move_amount := rows_by_level[g_state.level_index][entity.row_id].speed * g_state.dbg_speed_multiplier * dt
		rectangle.x += rectangle_move_amount

		warp_pos_on_left_side_x := rows_by_level[g_state.level_index][entity.row_id].start_x
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
		is_center_pos_inside_log_rectangle := check_collision_point_rectangle(center_pos, entity.rectangle)
		should_frogger_move_with_entity := is_center_pos_inside_log_rectangle 
		
		if should_frogger_move_with_entity 
		{
			speed := rows_by_level[g_state.level_index][entity.row_id].speed
			move_speed : f32 = speed * g_state.dbg_speed_multiplier
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
// game_reset_entities :: proc(mem: ^G_State)
// {
// 	g_state.entities = entities[:]
// }



@(export)
game_init :: proc()
{

	g_state = new(G_State)

	g_state.root_state = .Main_Menu

	g_state.dbg_show_grid = false
	g_state.dbg_is_frogger_unkillable = false

	g_state.frogger_pos = [2]f32{7,14}
	g_state.frogger_move_lerp.timer = Timer {
		amount = frogger_move_lerp_duration,
		duration = frogger_move_lerp_duration,
	}

	g_state.score_frogger_max_y_tracker = g_state.frogger_pos.y - 1

	g_state.animation_player_frogger_is_dying = { timer = { t = 0, playing = false, loop = false }, fps = 12, animation_name = .Frogger_Dying_Hit }

	g_state.dbg_camera_zoom = 1.0

	g_state.dbg_speed_multiplier = 1.0

	g_state.level_index = 0

	g_state.lives = 3

	g_state.camera.zoom = 1.0

}

score_increment :: proc(amount: int)
{
	old_score := g_state.score
	g_state.score += amount
	should_award_bonus_life := old_score < 20000 && g_state.score >= 20000
	if should_award_bonus_life
	{
		g_state.lives += 1
	}
}

frogger_reset :: proc()
{
	pos := [2]f32{7,14}

	g_state.frogger_pos = pos
	g_state.frogger_sprite_rotation = 0.0
	g_state.score_frogger_max_y_tracker = pos.y - 1
	g_state.is_lily_on_frogger = false
	timer_stop(&g_state.frogger_move_lerp.timer)
	g_state.countdown_timer_lose_life = global_countdown_timer_lose_life_duration
}


frogger_start_dying :: proc(animation_name: Animation_Name)
{
	g_state.animation_player_frogger_is_dying.animation_name = animation_name
	g_state.is_lily_on_frogger = false
	timer_stop(&g_state.frogger_move_lerp.timer)
	animation_timer_start(&g_state.animation_player_frogger_is_dying.timer)
	if g_state.lives != 0
	{
		g_state.lives -= 1
	}
}


root_state_main_menu_enter :: proc()
{
	frogger_reset()
	g_state.root_state = .Main_Menu
	g_state.level_index = 0
	for &present in g_state.is_frog_present_on_lilypads
	{
		present = false
	}
	g_state.score = 0
}

root_state_game :: proc()
{
	entities := entities_by_level[g_state.level_index]
	otters := otters_by_level[g_state.level_index]
	otter_spawn_descriptions := otter_spawn_descriptions_by_level[g_state.level_index]
	snakes := snakes_by_level[g_state.level_index]

	if key_is_just_pressed(.RETURN)
	{
		g_state.pause = !g_state.pause
	}

	skip_next_frame := false 

	when ODIN_DEBUG
	{
		camera_mod_key := Keyboard_Key.C
		level_mod_key := Keyboard_Key.L
		frogs_on_lilypad_mod_key := Keyboard_Key.F

		if key_is_down(camera_mod_key)
		{
			if key_is_down(.LEFTBRACKET) && key_is_down(.RIGHTBRACKET)
			{
				g_state.dbg_camera_offset_to_left = 0
			}
			else if key_is_just_pressed(.LEFTBRACKET)
			{
				g_state.dbg_camera_offset_to_left -= global_game_texture_grid_cell_size
			}
			else if key_is_just_pressed(.RIGHTBRACKET)
			{
				g_state.dbg_camera_offset_to_left += global_game_texture_grid_cell_size
			}

			if key_is_down(.MINUS) && key_is_down(.EQUALS)
			{
				g_state.dbg_camera_zoom = 1.0
			}
			else if key_is_just_pressed(.MINUS)
			{
				g_state.dbg_camera_zoom -= 0.1
			}
			else if key_is_just_pressed(.EQUALS)
			{
				g_state.dbg_camera_zoom += 0.1
			}
		}
		else if key_is_down(level_mod_key)
		{
			if key_is_just_pressed(.RIGHTBRACKET)
			{
				if g_state.level_index == 4
				{
					g_state.level_index = 0
				}
				else
				{
					g_state.level_index += 1
				}
			}
			else if key_is_just_pressed(.LEFTBRACKET)
			{
				if g_state.level_index == 0
				{
					g_state.level_index = 4
				}
				else
				{
					g_state.level_index -= 1
				}
			}
		}
		else if key_is_down(frogs_on_lilypad_mod_key)
		{
			if key_is_just_pressed(.RIGHTBRACKET)
			{
				for &present in g_state.is_frog_present_on_lilypads
				{
					if !present
					{
						present = true
						break
					}
				}
			}
		}
		else if key_is_just_pressed(.M)
		{
			root_state_main_menu_enter()
			return
		}
		else
		{
			skip_next_frame = key_is_just_pressed(.RIGHT)

			if key_is_down(.LEFTBRACKET) && key_is_down(.RIGHTBRACKET)
			{
				g_state.dbg_speed_multiplier = 5.0
			}
			else if key_is_down(.LEFTBRACKET)
			{
				g_state.dbg_speed_multiplier = 2.0
			}
			else if key_is_down(.RIGHTBRACKET)
			{
				g_state.dbg_speed_multiplier = 3.0
			}
			else
			{
				g_state.dbg_speed_multiplier = 1.0
			}

			if key_is_just_pressed(.T)
			{
				g_state.dbg_timer_lose_life_pause = !g_state.dbg_timer_lose_life_pause
			}			
		}
	}


	frame_time_uncapped := g_state.dt
	frame_time := min(frame_time_uncapped, f32(1.0/60.0))


	frogger_anim_frames := [?]Sprite_Clip_Name{
		.Frogger_Frame_1, .Frogger_Frame_2, .Frogger_Frame_1, .Frogger_Frame_0,
	}


	river := shape.Rectangle{0, 3, 14, 5}
	riverbed := shape.Rectangle{0, 1, 14,2}

	should_run_simulation := true
	if g_state.pause && !skip_next_frame
	{
		should_run_simulation = false
	}

	if should_run_simulation
	{	

		can_frogger_request_move := timer_is_complete(g_state.frogger_move_lerp.timer)  && !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer) && !countdown_is_playing(g_state.level_end_timer) && !g_state.pause && !countdown_is_playing(g_state.countdown_timer_game_over_display)
		if can_frogger_request_move  
		{
			frogger_move_direction := [2]f32{0,0}
			is_input_left := key_is_just_pressed(.LEFT) || gamepad_button_is_just_pressed( .FACE_LEFT)
			is_input_right := key_is_just_pressed(.RIGHT) || gamepad_button_is_just_pressed( .FACE_RIGHT)
			is_input_up := key_is_just_pressed(.UP) || gamepad_button_is_just_pressed( .FACE_UP)
			is_input_down := key_is_just_pressed(.DOWN) || gamepad_button_is_just_pressed( .FACE_DOWN)

			if is_input_left
			{
				frogger_move_direction.x = -1
				g_state.frogger_sprite_rotation  = 270
			}
			else if is_input_right
			{
				frogger_move_direction.x = 1
				g_state.frogger_sprite_rotation = 90
			} 
			else if is_input_up
			{
				frogger_move_direction.y = -1
				g_state.frogger_sprite_rotation = 0
			} 
			else if is_input_down
			{
				frogger_move_direction.y = 1
				g_state.frogger_sprite_rotation = 180
			}

			did_frogger_request_move := frogger_move_direction != [2]f32{0,0}

			if did_frogger_request_move 
			{
				timer_start(&frogger_anim_timer)

				frogger_next_pos := g_state.frogger_pos + frogger_move_direction
				frogger_next_center_pos := frogger_next_pos + 0.5
				
				will_frogger_be_out_of_left_bounds :=  frogger_next_center_pos.x < 0 && frogger_move_direction.x == -1
				will_frogger_be_out_of_right_bounds := frogger_next_center_pos.x > global_number_grid_cells_axis_x - 1 && frogger_move_direction.x == 1
				will_frogger_be_out_of_top_bounds := frogger_next_pos.y < 0 && frogger_move_direction.y == -1
				will_frogger_be_out_of_bottom_bounds := frogger_next_pos.y > global_number_grid_cells_axis_y - 2&& frogger_move_direction.y == 1
				
				will_frogger_be_out_of_bounds_on_next_move := will_frogger_be_out_of_left_bounds || 
					will_frogger_be_out_of_right_bounds || 
					will_frogger_be_out_of_top_bounds || 
					will_frogger_be_out_of_bottom_bounds

				frogger_center_pos := g_state.frogger_pos + 0.5
				if will_frogger_be_out_of_left_bounds && !(frogger_center_pos.x < 0) 
				{
					frogger_next_pos.x = 0

					if !(frogger_next_pos.x >= g_state.frogger_pos.x)
					{
						lerp_position_start(&g_state.frogger_move_lerp, g_state.frogger_pos, frogger_next_pos)
					}
				}
				else if will_frogger_be_out_of_right_bounds && !(frogger_center_pos.x > global_number_grid_cells_axis_x)
				{
					frogger_next_pos.x = global_number_grid_cells_axis_x - 1
					lerp_position_start(&g_state.frogger_move_lerp, g_state.frogger_pos, frogger_next_pos)
				}
				else if !will_frogger_be_out_of_bounds_on_next_move
				{
					lerp_position_start(&g_state.frogger_move_lerp, g_state.frogger_pos, frogger_next_pos)
				}
			}
		}

		should_update_lily := !g_state.is_lily_on_frogger
		if should_update_lily 
		{ 
			entity_that_lily_is_on := entities[lily_logs_to_spawn_on[g_state.level_index]]

			lily_lerp_timer_just_completed := false
			if timer_is_playing(lily_move_lerp.timer)
			{
				lily_relative_log_pos_x, lily_lerp_timer_just_completed = lerp_value_advance(&lily_move_lerp, frame_time)
			}

			if lily_lerp_timer_just_completed
			{
				timer_start(&lily_wait_timer)

				right_edge_of_log_x := entity_that_lily_is_on.rectangle.w - 1
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
				lily_wait_timer_just_completed = timer_advance(&lily_wait_timer, frame_time)
			}

			if lily_wait_timer_just_completed
			{
				move_amount_x := f32(0)

				right_edge_of_log_x := entity_that_lily_is_on.rectangle.w - 1
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
					lily_lerp_relative_log_end_x := lily_relative_log_pos_x + move_amount_x
					lerp_value_start(&lily_move_lerp, lily_relative_log_pos_x, lily_lerp_relative_log_end_x)
				}
			}


		}	
		

		should_check_for_lily_frogger_collision := !g_state.is_lily_on_frogger
		if should_check_for_lily_frogger_collision
		{
			frogger_center_pos    := g_state.frogger_pos + 0.5
			entity_that_lily_is_on   := entities[lily_logs_to_spawn_on[g_state.level_index]]
			lily_relative_log_rectangle := shape.Rectangle { lily_relative_log_pos_x, 0, 1, 1 }
			lily_world_rectangle        := shape.Rectangle{ 
				lily_relative_log_rectangle.x + entity_that_lily_is_on.rectangle.x, 
				lily_relative_log_rectangle.y + entity_that_lily_is_on.rectangle.y, 
				1, 
				1 
			}
			is_frogger_intersecting_lily := check_collision_point_rectangle(frogger_center_pos, lily_world_rectangle)
			if is_frogger_intersecting_lily
			{
				g_state.is_lily_on_frogger = true
			}

		}
		
		should_move_frogger := timer_is_playing(g_state.frogger_move_lerp.timer)
		if should_move_frogger 
		{
			g_state.frogger_pos = lerp_position_advance(&g_state.frogger_move_lerp, frame_time) 
		}


		{ // update timers
			timer_advance(&frogger_anim_timer, frame_time)
			countdown(&g_state.timer_is_active_score_200, frame_time)
			for &animation_player in animation_players
			{
				animation_player_advance(&animation_player, frame_time)
			}
		}


		{ // frogger death animation
			if animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer)
			{
				just_completed := animation_player_advance(&g_state.animation_player_frogger_is_dying, frame_time)
				if just_completed && g_state.lives != 0
				{
					frogger_reset()
				}
				else if just_completed && g_state.lives == 0
				{
					frogger_reset()
					g_state.countdown_timer_game_over_display = 6.0
				}
			}			
		}


		if !countdown_is_playing(g_state.level_end_timer) { // fly 
			just_completed := timer_advance(&fly_timer, frame_time)
			if just_completed
			{
				timer_start(&fly_timer)
				fly_is_active = !fly_is_active
				fly_lilypad_index += 1
				if fly_lilypad_index >= len(fly_lilypad_indices)
				{
					fly_lilypad_index = 0
				}
				for g_state.is_frog_present_on_lilypads[fly_lilypad_indices[fly_lilypad_index]]
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

		should_process_moving_frogger_with_intersecting_entities := !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer) 
		if should_process_moving_frogger_with_intersecting_entities
		{ 
			g_state.frogger_pos, g_state.frogger_move_lerp.end_pos = move_frogger_with_intersecting_entities(g_state.frogger_pos, g_state.frogger_move_lerp.end_pos, entities, frame_time)
		}

		{ // frogger get points for moving up
			point_value : int = 10
			should_award_points := g_state.frogger_pos.y <= g_state.score_frogger_max_y_tracker
			if should_award_points
			{
				g_state.score_frogger_max_y_tracker -= 1
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
				snake_is_beyond_left_side_of_screen := snake_world_rectangle.x <= -snake.rectangle.w

				median_y : f32 = 8
				frogger_is_on_or_below_median := g_state.frogger_pos.y >= median_y
			
				if snake.snake_behavior.snake_mode == .On_Median
				{
					snake.rectangle.x += snake.speed * frame_time * g_state.dbg_speed_multiplier
					entity_that_snake_is_on_is_offscreen_and_has_room_for_snake := entity_that_snake_is_on.rectangle.x < -snake.rectangle.w
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
					rel_right_turnaround_boundary : f32 = entity_that_snake_is_on.rectangle.w - 2

					snake.rectangle.x += snake.speed * frame_time * g_state.dbg_speed_multiplier
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
						frogger_is_closer_to_left_side_of_screen := g_state.frogger_pos.x <= global_number_grid_cells_axis_x / 2
						snake.rectangle.y = median_y
						if frogger_is_closer_to_left_side_of_screen
						{
							snake.rectangle.x = -snake.rectangle.w
							snake.speed = 1
						}
						else
						{	
							snake.rectangle.x = global_number_grid_cells_axis_x + snake.rectangle.w
							snake.speed = -1
						}
					} 

				}

			}
		}

		{
			timer_crocodile_inactive_duration : f32 = 6.0

			should_process_crocodile_timers := g_state.level_index != 0
			if should_process_crocodile_timers 
			{
				if countdown_and_did_just_complete(&timer_crocodile_inactive, frame_time)
				{
					timer_crocodile_peek = 2.0
				}
			
				if countdown_and_did_just_complete(&timer_crocodile_peek, frame_time)
				{
					timer_crocodile_attack = 1.0
				}

				if countdown_and_did_just_complete(&timer_crocodile_attack, frame_time)
				{
					timer_crocodile_inactive = timer_crocodile_inactive_duration
					current_crocodile_lilypad_id_index += 1
					should_wrap_index := current_crocodile_lilypad_id_index >= len(lilypad_ids_crocodile)
					if should_wrap_index
					{
						current_crocodile_lilypad_id_index = 0
					}
				}
			}
			else
			{
				timer_crocodile_peek = 0
				timer_crocodile_attack = 0
				timer_crocodile_inactive = timer_crocodile_inactive_duration
			}
		}

		

		{ // otters
			for &otter in otters
			{
				just_finished_attacking := false
				if timer_is_playing(otter.timer_attack)
				{
					just_finished_attacking = timer_advance(&otter.timer_attack, frame_time)
				}
				// place otters if they intersect with a entity
				is_otter_intersecting_with_any_entities := false
				intersecting_entity := Entity {}
				for entity in entities
				{
					is_otter_intersecting_with_any_entities = is_otter_intersecting_with_any_entities || check_collision_rectangles(otter.entity.rectangle, entity.rectangle)
					intersecting_entity := entity
				}

				frogger_rectangle := shape.Rectangle { g_state.frogger_pos.x - 0.2 , g_state.frogger_pos.y, 1.4, 1}

				is_otter_intersecting_with_frogger := check_collision_rectangles(otter.entity.rectangle, frogger_rectangle)

				should_otter_kill_frogger := is_otter_intersecting_with_frogger && !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer) && !g_state.dbg_is_frogger_unkillable
				if should_otter_kill_frogger
				{
					entity_intersecting_with_frogger := Entity {}
					for entity in entities
					{
						frogger_center_pos := g_state.frogger_pos + 0.5
						is_frogger_intersecting_with_entity := check_collision_point_rectangle(frogger_center_pos, entity.rectangle)
						if is_frogger_intersecting_with_entity
						{
							entity_intersecting_with_frogger = entity
						}
					}
					otter.entity.speed = entity_intersecting_with_frogger.speed
					timer_start(&otter.timer_attack)
					frogger_start_dying(.Frogger_Dying_Hit)
				}

				is_otter_out_of_left_bounds := otter.entity.speed < 0 && otter.entity.rectangle.x < -otter.entity.rectangle.w
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

				otter.entity.rectangle.x += otter.entity.speed * frame_time * g_state.dbg_speed_multiplier


			}
		}

		should_check_pre_win_condition_frogger_is_killed := !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer)  && !g_state.dbg_is_frogger_unkillable
		if should_check_pre_win_condition_frogger_is_killed
		{
			{ // crocodile attack
				if countdown_is_playing(timer_crocodile_attack)
				{
					lilypad_id_crocodile_is_in := lilypad_ids_crocodile[current_crocodile_lilypad_id_index]
					lilypad := lilypads[lilypad_id_crocodile_is_in]
					frogger_center_pos := g_state.frogger_pos + 0.5
					frogger_in_crocodile_mouth := check_collision_point_rectangle(frogger_center_pos, lilypad)
					if frogger_in_crocodile_mouth
					{
						frogger_start_dying(.Frogger_Dying_Hit)
					}
				}
			}
		}


		should_check_for_win_condtions := !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer) && !countdown_is_playing(g_state.level_end_timer)
		if should_check_for_win_condtions 
		{
			for lilypad, i in lilypads 
			{	
				frogger_center_pos := g_state.frogger_pos + 0.5
				is_frogger_on_lilypad := check_collision_point_rectangle(frogger_center_pos, lilypad)
				is_there_already_a_frog_here := g_state.is_frog_present_on_lilypads[i]
				did_get_frogger_home := is_frogger_on_lilypad && !is_there_already_a_frog_here
				
				if did_get_frogger_home 
				{
					g_state.is_frog_present_on_lilypads[i] = true

					// NOTE(jblat): The extra 10 is essentially to give the effect of getting the 10 points from advancing a tile
					// 10 = frog safely gets gome
					score_amount_get_frogger_home := 60
					score_increment(score_amount_get_frogger_home)
					

					did_frogger_get_fly := fly_lilypad_indices[fly_lilypad_index] == i && fly_is_active
					if did_frogger_get_fly
					{
						score_amount_frogger_get_fly := 200
						score_increment(score_amount_frogger_get_fly)
						g_state.timer_is_active_score_200 = 2.0
						g_state.pos_score_200.x = lilypad.x
						g_state.pos_score_200.y = lilypad.y - 1
					}

					if g_state.is_lily_on_frogger
					{
						score_amount_get_lily_home := 200
						score_increment(score_amount_get_lily_home)
						g_state.timer_is_active_score_200 = 2.0
						g_state.pos_score_200.x = lilypad.x
						g_state.pos_score_200.y = lilypad.y - 1
					}

					g_state.countdown_timer_display_last_cycle_completion = 4.0

					// so i think frogger counts two ticks for every second? based on timing an emulated version
					remaining_seconds := int(g_state.countdown_timer_lose_life) * 2
					time_bonus : int = 10 * remaining_seconds
					score_increment(time_bonus)

					g_state.last_cycle_completion_in_seconds = i32(remaining_seconds)
					frogger_reset()
				}
			}

			number_of_frogs_on_lilypad := 0
			for present in g_state.is_frog_present_on_lilypads
			{
				if present
				{
					number_of_frogs_on_lilypad += 1
				}
			}

			is_all_frogs_on_lilypads := number_of_frogs_on_lilypad == len(g_state.is_frog_present_on_lilypads)
			if is_all_frogs_on_lilypads
			{
				// 1000 for saving all frogs
				score_increment(1000)
				g_state.level_end_timer = global_level_end_timer_duration
				// TODO(jalfonso): eventually i think this level stuff will be calculated by modulo
				g_state.level_index += 1
				if g_state.level_index > 4
				{
					g_state.level_index = 0
				}
			}
		}

		
		if countdown_and_did_just_complete(&g_state.level_end_timer, frame_time)
		{
			for &present in g_state.is_frog_present_on_lilypads
			{
				present = false
			}
		}
		

		should_process_countdown_timer := !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer) && !g_state.dbg_timer_lose_life_pause && !countdown_is_playing(g_state.countdown_timer_game_over_display) && !countdown_is_playing(g_state.level_end_timer)
		if should_process_countdown_timer
		{
			if countdown_and_did_just_complete(&g_state.countdown_timer_lose_life, frame_time)
			{
				frogger_start_dying(.Frogger_Dying_Hit)					
			}
		}

		countdown(&g_state.countdown_timer_display_last_cycle_completion, frame_time)

		if countdown_and_did_just_complete(&g_state.countdown_timer_game_over_display, frame_time)
		{
			root_state_main_menu_enter()
			return // don't process anything else here	
		}
		
		should_check_for_frogger_is_killed := !animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer)  && 
			!g_state.dbg_is_frogger_unkillable

		if should_check_for_frogger_is_killed 
		{
			is_frogger_out_of_bounds := g_state.frogger_pos.x + 0.5 < 0 || g_state.frogger_pos.x - 0.5 >= global_number_grid_cells_axis_x -1 || g_state.frogger_pos.y < 0 || g_state.frogger_pos.y > global_number_grid_cells_axis_y
			if is_frogger_out_of_bounds 
			{
				frogger_start_dying(.Frogger_Dying_Drown)
			}

			frogger_center_pos := g_state.frogger_pos + 0.5
			for entity in entities
			{
				is_frogger_intersecting_entity := check_collision_point_rectangle(frogger_center_pos, entity.rectangle)
				can_entity_kill_frogger := entity.collision_behavior == .Kill_Frogger
				is_frogger_hit_by_entity := is_frogger_intersecting_entity && can_entity_kill_frogger

				if is_frogger_hit_by_entity
				{
					frogger_start_dying(.Frogger_Dying_Hit)
				}
			}

			is_frogger_on_safe_entity := false
			is_frogger_moving := !timer_is_complete(g_state.frogger_move_lerp.timer)
			is_frogger_in_river_region := frogger_center_pos.y > river.y && frogger_center_pos.y < river.y + river.h
			is_frogger_in_riverbed := check_collision_point_rectangle(frogger_center_pos, riverbed)

			is_frogger_on_one_of_the_open_lilypads := false
			for lilypad, i in lilypads
			{
				is_frogger_on_lilypad := check_collision_point_rectangle(frogger_center_pos, lilypad)
				is_frog_already_here := g_state.is_frog_present_on_lilypads[i]
				is_frogger_on_one_of_the_open_lilypads = is_frogger_on_one_of_the_open_lilypads || (is_frogger_on_lilypad && !is_frog_already_here)
			}

			did_frogger_collide_with_riverbed := is_frogger_in_riverbed && !is_frogger_on_one_of_the_open_lilypads

			if did_frogger_collide_with_riverbed
			{
				frogger_start_dying(.Frogger_Dying_Drown)
			}

			for entity in entities
			{
				is_frogger_center_pos_inside_entity := check_collision_point_rectangle(frogger_center_pos, entity.rectangle)

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

						clip := animation_get_frame_sprite_clip_id(animation_player.timer.t, animation_player.fps, global_sprite_animations[animation_player.animation_name])

						if animation_player.animation_name == .Alligator
						{
							if clip == .Alligator_Mouth_Open
							{
								hit_box := alligator_hit_box_relative_mouth_open
								hit_box.x += entity.rectangle.x
								hit_box.y += entity.rectangle.y

								frogger_center_pos := g_state.frogger_pos + 0.5
								did_frogger_collide_with_hitbox := check_collision_point_rectangle(frogger_center_pos, hit_box)
								if did_frogger_collide_with_hitbox
								{
									frogger_start_dying(.Frogger_Dying_Hit)
								}
							}
						}
						else if animation_player.animation_name == .Diving_Turtle
						{
							is_frogger_center_pos_inside_turtle_rectangle := check_collision_point_rectangle(frogger_center_pos,  entity.rectangle)
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
					snake_relative_hitbox := shape.Rectangle{0, 0, 1, 1}
					if snake.speed > 0
					{
						// flipped
						snake_relative_hitbox = shape.Rectangle{1, 0, 1, 1}
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

					is_frogger_intersecting_snake_hitbox := check_collision_point_rectangle(frogger_center_pos, snake_world_hitbox)

					if is_frogger_intersecting_snake_hitbox
					{
						frogger_start_dying(.Frogger_Dying_Hit)
					}
				}
			}
		}	
	}



	{ // debug options
		if key_is_just_pressed(.F1) 
		{
			g_state.dbg_show_grid = !g_state.dbg_show_grid
		}

		if key_is_just_pressed(.F2)
		{
			g_state.dbg_is_frogger_unkillable = !g_state.dbg_is_frogger_unkillable
		}

		if key_is_just_pressed(.F3)
		{
			g_state.dbg_show_entity_bounding_rectangles = !g_state.dbg_show_entity_bounding_rectangles
		}

		if key_is_just_pressed(.F4)
		{
			g_state.dbg_show_level = !g_state.dbg_show_level
		}

	}


	// NOTE(jblat): For mouse, see: https://github.com/raysan5/raylib/blob/master/examples/core/core_window_letterbox.c

	{ // DRAW TO RENDER TEXTURE
		// camera := rl.Camera2D {
		// 	offset = [2]f32{g_state.dbg_camera_offset_to_left, 0},
		// 	target = [2]f32{0,0},
		// 	rotation = 0,
		// 	zoom = g_state.dbg_camera_zoom,
		// }


		pirc.render_bg_clear(&g_state.render_cmds, 200,200,200,255)


		{ // draw background
			scale : f32 =  global_game_texture_grid_cell_size / global_sprite_sheet_cell_size
			pirc.render_texture_ex(&g_state.render_cmds, g_state.textures[.Background], [2]f32{0,0}, scale)
		}

		should_display_last_cycle_time := countdown_is_playing(g_state.countdown_timer_display_last_cycle_completion)
		if should_display_last_cycle_time 
		{ 
			text := fmt.ctprint("TIME:", g_state.last_cycle_completion_in_seconds)
			center_screen_on_median := [2]f32{global_number_grid_cells_axis_x / 2, 8.5}
			// rlgrid.draw_text_on_grid_with_background(
			// 	g_state.font, 
			// 	text, 
			// 	center_screen_on_median, 
			// 	0.7, 
			// 	global_game_texture_grid_cell_size, 
			// 	text_tint = RED, background_color = BLACK, 
			// 	horizontal_text_justification = .Centered, vertical_text_justification = .Centered
			// )
		}

		should_display_game_over := countdown_is_playing(g_state.countdown_timer_game_over_display)
		if should_display_game_over 
		{ 
			// center_screen_on_median := [2]f32{global_number_grid_cells_axis_x / 2, 8.5}
			// rlgrid.draw_text_on_grid_with_background(
			// 	g_state.font, 
			// 	"GAME OVER", 
			// 	center_screen_on_median, 
			// 	0.7, 
			// 	global_game_texture_grid_cell_size, 
			// 	text_tint = RED, background_color = BLACK, 
			// 	horizontal_text_justification = .Centered, vertical_text_justification = .Centered
			// )
		}
		


		{ // draw entities
			for entity, i in entities 
			{
				switch sd in entity.sprite_data
				{
					case Sprite_Clip_Name:
					{
						pos := [2]f32{entity.rectangle.x, entity.rectangle.y}
						draw_sprite_sheet_clip_on_game_texture_grid(sd, pos)
					}
					case Animation_Player_Name:
					{
						animation_player := animation_players[sd]
						pos := [2]f32{entity.rectangle.x, entity.rectangle.y}
						draw_sprite_sheet_clip_on_game_texture_grid_from_animation_player(animation_player, pos)
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
						pos := [2]f32{r.x, r.y}
						draw_sprite_sheet_clip_on_game_texture_grid_from_animation_player(animation_player, pos, flip_x = flip_x)					
					}
				}
			}
		}

		{ // draw crocodile
			lilypad_rectangle := lilypads[lilypad_ids_crocodile[current_crocodile_lilypad_id_index]]
			lilypad_pos := [2]f32{lilypad_rectangle.x, lilypad_rectangle.y}
			is_frog_here := g_state.is_frog_present_on_lilypads[lilypad_ids_crocodile[current_crocodile_lilypad_id_index]]

			if countdown_is_playing(timer_crocodile_peek) && !is_frog_here
			{
				draw_sprite_sheet_clip_on_game_texture_grid(.Crocodile_Head_Peek, lilypad_pos)
			}
			else if countdown_is_playing(timer_crocodile_attack) && !is_frog_here
			{
				draw_sprite_sheet_clip_on_game_texture_grid(.Crocodile_Head_Attack, lilypad_pos)
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
					draw_sprite_sheet_clip_on_grid(.Otter_Attacking, otter.entity.rectangle, global_game_texture_grid_cell_size, 0, flip_x, false)
				}
				else
				{
					draw_sprite_sheet_clip_on_grid(.Otter_Peek, otter.entity.rectangle, global_game_texture_grid_cell_size, 0, flip_x, false)
				}
			}

		}	


		if fly_is_active 
		{ // draw fly
			lilypad_index := fly_lilypad_indices[fly_lilypad_index%len(fly_lilypad_indices)]
			dst_rect := lilypads[lilypad_index]
			render_dst_rect := transmute(shape.Rectangle)(dst_rect)
			draw_sprite_sheet_clip_on_grid(.Fly, render_dst_rect, global_game_texture_grid_cell_size, 0 )
			// rlgrid.draw_grid_texture_clip_on_grid(g_state.texture_sprite_sheet, clip, global_sprite_sheet_cell_size,  dst_rect, global_game_texture_grid_cell_size, 0)
		}

		
		{ // draw frogs on lilypads
			progress_of_level_end_timer := percentage_remaining(g_state.level_end_timer, 4.0)

			for lp, i in lilypads
			{	lp_pos := [2]f32 {lp.x, lp.y}

				is_there_a_frog_on_this_lilypad := g_state.is_frog_present_on_lilypads[i]
				if is_there_a_frog_on_this_lilypad
				{
					frog_p : f32 = f32(i) / f32(len(lilypads))
					if progress_of_level_end_timer == 1
					{
						draw_sprite_sheet_clip_on_game_texture_grid(.Happy_Frog_Closed_Mouth, lp_pos)
					}
					else
					{
						if frog_p >= progress_of_level_end_timer
						{
							draw_sprite_sheet_clip_on_game_texture_grid(.Happy_Frog_Closed_Mouth, lp_pos)
						}
						else
						{
							draw_sprite_sheet_clip_on_game_texture_grid(.Happy_Frog_Open_Mouth, lp_pos)							
						}
					}
				}
			}
		}

		should_draw_frogger := !countdown_is_playing(g_state.countdown_timer_game_over_display)
		if should_draw_frogger 
		{
			if animation_timer_is_playing(g_state.animation_player_frogger_is_dying.timer)
			{
				draw_sprite_sheet_clip_on_game_texture_grid_from_animation_player(g_state.animation_player_frogger_is_dying, g_state.frogger_pos)
			}
			else
			{
				clip := animation_get_frame_sprite_clip_id(frogger_anim_timer.amount, 12, frogger_anim_frames[:])
				draw_sprite_sheet_clip_on_game_texture_grid(clip, g_state.frogger_pos, g_state.frogger_sprite_rotation)
			}
		}

		
		{ // draw lily
			if g_state.is_lily_on_frogger
			{
				lily_pos := g_state.frogger_pos
				rotation := g_state.frogger_sprite_rotation
				if rotation == 0.0
				{
					lily_pos.y += 0.15
				}
				else if rotation == 90.0
				{
					lily_pos.x -= 0.15
				}
				else if rotation == 180.0
				{
					lily_pos.y -= 0.15
				}
				else if rotation == 270.0
				{
					lily_pos.x += 0.15
				}
				draw_sprite_sheet_clip_on_game_texture_grid(.Lily_Frame_0, lily_pos, rotation = rotation)
			}
			else 
			{
				entity_that_lily_is_on := lily_logs_to_spawn_on[g_state.level_index]
				entity := entities[entity_that_lily_is_on]
				lily_pos := [2]f32{entity.rectangle.x + lily_relative_log_pos_x, entity.rectangle.y}
				direction_rotation_map := [Direction]f32 { .Up = 0, .Down = 180, .Right = 90, .Left = 270}
				rotation : f32 = direction_rotation_map[lily_direction]
				draw_sprite_sheet_clip_on_game_texture_grid(.Lily_Frame_0, lily_pos, rotation = rotation)
			}
		}


		if countdown_is_playing(g_state.timer_is_active_score_200)
		{
			draw_sprite_sheet_clip_on_game_texture_grid(.Score_200, g_state.pos_score_200)
		}

		{ // lives
			for i in 0 ..< g_state.lives
			{
				scale : f32 = 0.7
				pos := [2]f32{f32(i) * scale, global_number_grid_cells_axis_y - 1}
				draw_sprite_sheet_clip_on_game_texture_grid(.Frogger_Frame_0, pos, scale_x = scale, scale_y = scale)
			}
		}

		
	
		if g_state.dbg_show_grid 
		{ 	
			for x : f32 = -g_state.camera.offset.x; x < global_number_grid_cells_axis_x; x += 1 
			{
				render_x := x * global_game_texture_grid_cell_size
				render_start_y : f32 = 0
				render_end_y := game_resolution_height
				pirc.render_line(&g_state.render_cmds, render_x, render_start_y, render_x, render_end_y, 1, 255, 255, 255, 255)
				// rl.DrawLineV([2]f32{render_x, render_start_y}, [2]f32{render_x, render_end_y}, rl.WHITE)
			}

			for y : f32 = 0; y < global_number_grid_cells_axis_y; y += 1 
			{
				render_y := y * global_game_texture_grid_cell_size
				render_start_x : f32 = -g_state.camera.offset.x
				render_end_x := game_resolution_width
				pirc.render_line(&g_state.render_cmds, render_start_x, render_y, render_end_x, render_y, 1, 255, 255, 255, 255)
				// rl.DrawLineV([2]f32{render_start_x, render_y}, [2]f32{render_end_x, render_y}, rl.WHITE)
			}
		}

		
		if g_state.dbg_show_entity_bounding_rectangles
		{	
			frogger_rectangle := shape.Rectangle{g_state.frogger_pos.x, g_state.frogger_pos.y, 1, 1}
			pirc.grid_render_rectangle_lines(&g_state.render_cmds, frogger_rectangle, global_game_texture_grid_cell_size, 4, color = [4]u8{0,255,0,255})
			// rlgrid.draw_rectangle_lines_on_grid(frogger_rectangle, 4, GREEN, global_game_texture_grid_cell_size)
		}

		if g_state.dbg_show_level
		{
			text_level := fmt.ctprintf("level: %d", g_state.level_index + 1)
			text_pos_level := [2]f32 {1, 8}
			// rlgrid.draw_text_on_grid(g_state.font, text_level, text_pos_level, 0.7, 0, rl.WHITE, global_game_texture_grid_cell_size)
		}

		
		{ // heads up display
			heads_up_display_font_size : f32 = 0.7

			one_up_pos := [2]f32{4,0}

			// rlgrid.draw_text_on_grid_right_justified(g_state.font, "1-UP", one_up_pos, heads_up_display_font_size, 0, rl.WHITE, f32(global_game_texture_grid_cell_size))

			score_text := fmt.ctprintf("%05d", g_state.score)
			score_text_pos := [2]f32 {
				one_up_pos.x,
				one_up_pos.y + heads_up_display_font_size
			}

			// rlgrid.draw_text_on_grid_right_justified(g_state.font, score_text, score_text_pos, heads_up_display_font_size, 0, rl.WHITE, f32(global_game_texture_grid_cell_size))
		}

		{ // countdown timer
			max_rectangle_width : f32 = 7.5
			percentage_full := percentage_full(g_state.countdown_timer_lose_life, global_countdown_timer_lose_life_duration)
			rectangle_width := max_rectangle_width * percentage_full

			timer_rectangle := shape.Rectangle { global_number_grid_cells_axis_x - 2, global_number_grid_cells_axis_y - 0.5, rectangle_width, 0.5 }
			color := GREEN
			if percentage_full < 0.2
			{
				color = RED
			}
			// rlgrid.draw_rectangle_on_grid_right_justified(timer_rectangle, color, global_game_texture_grid_cell_size)
		}

		// rl.EndMode2D()

		// rl.EndTextureMode()
	}
}


root_state_main_menu :: proc()
{
	@(static)visible: bool
	blink_timer_duration :: 0.3
	@(static)blink_timer: f32 = blink_timer_duration

	dt := g_state.dt
	if countdown_and_did_just_complete(&blink_timer, dt)
	{
		visible = !visible
		blink_timer = blink_timer_duration
	}

	is_input_start := key_is_just_pressed(.RETURN) || gamepad_button_is_just_pressed(.FACE_DOWN)  
	if is_input_start
	{
		g_state.countdown_timer_display_last_cycle_completion = 0
		g_state.lives = 3
		g_state.root_state = .Game
		g_state.animation_player_frogger_is_dying.timer.playing = false
		frogger_reset()
	}

	pirc.render_bg_clear(&g_state.render_cmds, 0, 0, 0, 255)

	title_centered_pos := [2]f32{global_number_grid_cells_axis_x / 2, 5}
	title_centered_pos.x -= 3 // only doing this until i get text centering working
	pirc.grid_render_text_tprintf(&g_state.render_cmds, title_centered_pos, g_state.font, 2, {0, 255, 0, 255}, global_game_texture_grid_cell_size, "FROGGER")
	title_centered_pos.y += 2

	if visible
	{
		press_enter_centered_pos := [2]f32{global_number_grid_cells_axis_x / 2, 8}
		press_enter_centered_pos.x -= 4
		pirc.grid_render_text_tprintf(&g_state.render_cmds, press_enter_centered_pos, g_state.font, 0.7, {255, 255, 255, 255}, global_game_texture_grid_cell_size, "press start to play")
		
		// rlgrid.draw_text_on_grid_centered(g_state.font, "press enter to play", press_enter_centered_pos, 0.7, 0, rl.WHITE, global_game_texture_grid_cell_size)		
	}

	credits_centered_pos := [2]f32{global_number_grid_cells_axis_x / 2, global_number_grid_cells_axis_y - 3}
	credits_centered_pos.x -= 3
	pirc.grid_render_text_tprintf(&g_state.render_cmds, credits_centered_pos, g_state.font, 0.3, {255, 255, 255, 255}, global_game_texture_grid_cell_size, "a fandmade frogger remake")
	
	// rlgrid.draw_text_on_grid_centered(g_state.font, "a fanmade frogger remake", credits_centered_pos, 0.3, 0, rl.WHITE, global_game_texture_grid_cell_size)

	credits_centered_pos.y += 0.3
}


set_delta_time :: proc(dt : f32)
{
	g_state.dt =  dt
}


@(export)
game_update :: proc()
{
	switch g_state.root_state
	{
		case .Main_Menu: root_state_main_menu()
		case .Game: root_state_game()
	}

}



@(export)
game_shutdown :: proc()
{
	// when ODIN_OS != .JS { // no need to save this in web

	// 	window_pos    := rl.GetWindowPosition()
	// 	screen_width  := rl.GetScreenWidth()
	// 	screen_height := rl.GetScreenHeight()

	// 	window_save_data := Window_Save_Data {i32(window_pos.x), i32(window_pos.y), screen_width, screen_height}
	// 	bytes_window_save_data := mem.ptr_to_bytes(&window_save_data)

	// 	ok := write_entire_file(global_filename_window_save_data, bytes_window_save_data)
	// 	if !ok
	// 	{
	// 		fmt.printfln("Error opening/creating Window Save Data File")
	// 	}
	// 	// file_window_save_data, err := os2.open(global_filename_window_save_data, {.Write, .Create})
	// 	// if err != nil
	// 	// {
	// 	// 	fmt.printfln("Error opening/creating Window Save Data File: %v", err)
	// 	// }
	// 	// n_bytes_written, write_err := os2.write(file_window_save_data, bytes_window_save_data)
	// 	// if write_err != nil
	// 	// {
	// 	// 	fmt.printfln("Error saving Window Save Data: %v", write_err)
	// 	// }
	// 	// did_not_write_all_bytes :=  n_bytes_written != size_of(window_save_data)
	// 	// if did_not_write_all_bytes
	// 	// {
	// 	// 	fmt.printfln("Error saving Window Save Data: number bytes written = %v, number bytes expected = %v", n_bytes_written, size_of(window_save_data))
	// 	// }
	// }
}


// should_run :: proc() -> bool {
// 	when ODIN_OS != .JS {
// 		// Never run this proc in browser. It contains a 16 ms sleep on web!
// 		if rl.WindowShouldClose() {
// 			return false
// 		}
// 	}

// 	return true
// }


// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
