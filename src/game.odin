package game

import rl "vendor:raylib"
import "core:math"

image_data_sprite_sheet := #load("frogger_sprite_sheet_modified.png")
image_data_background   := #load("frogger_background_modified.png")

sprite_sheet_cell_size : f32 = 16




Entity :: struct
{
	rectangle : rl.Rectangle,
	speed     : f32,
	warp_boundary_extension : f32,
}


Timer :: struct
{
	amount: f32,
	duration: f32,
	loop: bool,
}



timer_is_complete :: proc(timer: Timer) -> bool
{
	if timer.amount >= timer.duration
	{
		return true
	}
	return false
}


timer_advance :: proc(timer: ^Timer, dt: f32)
{
	timer.amount += dt
	timer.amount = min(timer.amount, timer.duration)
	if timer.loop && timer_is_complete(timer^)
	{
		timer_start(timer)
	}
}

timer_percentage :: proc(timer: Timer) -> f32
{
	t := timer.amount / timer.duration
	return t
}


timer_start :: proc(timer: ^Timer)
{
	timer.amount = 0
}


timer_stop :: proc(timer: ^Timer)
{
	timer.amount = timer.duration
}


Game_Memory :: struct
{
	// GRID
	cell_size: f32,
	number_of_grid_cells_on_axis_x : f32,
	number_of_grid_cells_on_axis_y : f32,
	
	// VIEW
	initial_window_width : f32,
	initial_window_height: f32,
	game_render_target: rl.RenderTexture,
	game_screen_width: f32,
	game_screen_height: f32,

	// Spritesheets
	texture_sprite_sheet : rl.Texture2D,
	texture_background   : rl.Texture2D,


	// DEBUG
	dbg_show_grid : bool,
	dbg_is_frogger_unkillable : bool,
	dbg_show_entity_bounding_rectangles : bool,

	// GAME

	// frogger
	frogger_pos       : [2]f32,
	frogger_move_lerp_timer     : Timer,
	frogger_move_lerp_start_pos : [2]f32,
	frogger_move_lerp_end_pos   : [2]f32,

	frogger_sprite_rotation: f32,

	// win
	is_frogs_on_lilypad :[5]bool,
	score :int,

	// entities
	floating_logs :[]Entity,

	turtles :[]Entity,
	diving_turtles :[]Entity,

	vehicles :[]rl.Rectangle,
	vehicle_positions :[][2]f32,
	vehicle_rectangles :[]rl.Rectangle,
	vehicles_speed :[]f32,
	vehicles_colors :[]rl.Color,

	pause : bool,
}


gmem: ^Game_Memory


lilypads := [5]rl.Rectangle{
	{.5,   2, 1, 1},
	{3.5,  2, 1, 1},
	{6.5,  2, 1, 1},
	{9.5,  2, 1, 1},
	{12.5, 2, 1, 1},
}


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
	dst_midpoint := [2]f32{dst_rect.width / 2, dst_rect.height / 2}
	dst_rect.x += dst_midpoint.x
	dst_rect.y += dst_midpoint.y
	rl.DrawTexturePro(sprite_sheet, src_rect, dst_rect, [2]f32{dst_midpoint.x, dst_midpoint.y}, rotation, rl.WHITE)
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

initial_window_width := 640
initial_window_height := 640


@(export)
game_init_platform :: proc()
{
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(i32(initial_window_width), i32(initial_window_height), "Frogger [For Educational Purposes Only]")
	rl.SetTargetFPS(60)
}


happy_frog_sprite_clip_closed_mouth := rl.Rectangle{3, 6, 1, 1}

is_frogs_on_lilypad := [5]bool{true, true, true, true, false}


floating_logs := [?]Entity{
	{ {0,  3,  4, 1}, 2, 0},
	{ {6,  3,  4, 1}, 2, 0},
	{ {13, 3, 4, 1}, 2, 0},

	{ {0, 5, 6, 1}, 3 , 0},
	{ {9, 5, 6, 1}, 3 , 0},
	

	{ {0,  6, 3, 1}, 1 , 0},
	{ {6,  6, 3, 1}, 1 , 0},
	{ {11, 6, 3, 1}, 1,  0}
}

long_log_sprite_clip   := rl.Rectangle{3, 2, 6, 1}
medium_log_sprite_clip := rl.Rectangle{4, 3, 4, 1}
small_log_sprite_clip  := rl.Rectangle{6, 8, 3, 1}

floating_logs_sprite_clips := [?]rl.Rectangle {
	medium_log_sprite_clip, medium_log_sprite_clip, medium_log_sprite_clip,
	long_log_sprite_clip,   long_log_sprite_clip,
	small_log_sprite_clip,  small_log_sprite_clip, small_log_sprite_clip,
}


turtles := [?]Entity {
	{ {6,  4, 1, 1}, -2, 4}, { {7,  4, 1, 1}, -2, 4},
	{ {10, 4, 1, 1}, -2, 4}, { {11, 4, 1, 1}, -2, 4},
	{ {14, 4, 1, 1}, -2, 4}, { {15, 4, 1, 1}, -2, 4},
	
	{ {0, 7, 1, 1}, -2, 0}, { {1, 7, 1, 1}, -2, 0}, { {2,  7, 1, 1}, -2, 0},
	{ {4, 7, 1, 1}, -2, 0}, { {5, 7, 1, 1}, -2, 0}, { {6,  7, 1, 1}, -2, 0},
	{ {8, 7, 1, 1}, -2, 0}, { {9, 7, 1, 1}, -2, 0}, { {10, 7, 1, 1}, -2, 0},
}


diving_turtles := [?]Entity {
	{ {2, 4, 1, 1},  -2 , 4}, { {3, 4, 1, 1}, -2,  4  },
	{ {12, 7, 1, 1}, -2 , 0}, { {13, 7, 1, 1}, -2, 0 }, { {14, 7, 1, 1}, -2, 0}
}

regular_turtles_anim_fps : f32 = 3
regular_turtles_anim_timer : f32 = 0

diving_turtles_anim_fps : f32 = regular_turtles_anim_fps

diving_turtles_anim_timers := [?]f32 {
	0, 0,
	1, 1, 1,
}



frogger_anim_timer := Timer {
	amount = 0.25,
	duration = 0.25,
}


vehicles := [?]rl.Rectangle{
	{10, 13, 1, 1},
	{6,  13, 1, 1},
	{2,  13, 1, 1},

	{5,  12, 1, 1},
	{9,  12, 1, 1},
	{13, 12, 1, 1 },
	
	{10, 11, 1, 1},
	{6,  11, 1, 1},
	{2,  11, 1, 1},

	{1, 10, 1, 1},
	{5, 10, 1, 1},
	{9, 10, 1, 1},

	{1, 9, 2, 1},
	{6, 9, 2, 1},
}

vehicle_positions := [?][2]f32{
	{10, 13}, {6, 13}, {2,  13},
	{5,  12}, {9, 12}, {13, 12},
	{10, 11}, {6, 11}, {2,  11},
	{1,  10}, {5, 10}, {9,  10},
	{1,  9},  {2, 9},  {6, 9},   {7, 9}
}

yellow_car_sprite_sheet_clip := rl.Rectangle{3,0,1,1}
bulldozer_sprite_sheet_clip  := rl.Rectangle{4,0,1,1}
purple_car_sprite_sheet_clip := rl.Rectangle{7,0,1,1}
white_car_sprite_sheet_clip  := rl.Rectangle{8,0,1,1}
truck_sprite_sheet_clip      := rl.Rectangle{5,0,2,1}

vehicle_sprite_sheet_clips := [?]rl.Rectangle{
	yellow_car_sprite_sheet_clip, yellow_car_sprite_sheet_clip, yellow_car_sprite_sheet_clip,
	bulldozer_sprite_sheet_clip,  bulldozer_sprite_sheet_clip,  bulldozer_sprite_sheet_clip,
	purple_car_sprite_sheet_clip, purple_car_sprite_sheet_clip, purple_car_sprite_sheet_clip,
	white_car_sprite_sheet_clip,  white_car_sprite_sheet_clip,  white_car_sprite_sheet_clip,
	truck_sprite_sheet_clip,  truck_sprite_sheet_clip
}

vehicles_speed := [?]f32{
	-1,
	-1,
	-1,

	2,
	2,
	2,

	-2,
	-2,
	-2,

	2,
	2,
	2,

	-2, -2,
	-2, - 2
}

fly_lilypad_indices := [?]int{3, 1, 3, 1, 0, 2, 4, 3, 1, 0}
fly_lilypad_index : int  = 0 // index into array above, not the lilypad
fly_timer := Timer{
	amount = 0,
	duration = 4.0,
}
fly_is_active : bool     = false
fly_sprite_sheet_clip   := rl.Rectangle {2, 6, 1, 1}


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

lily_logs_to_spawn_on := [?]int{5, 1, 3}
lily_log_to_spawn_on_index : int = 0 // index into above array


frogger_death_anim_fps : f32 = 3
frogger_death_anim_frames := [?]rl.Rectangle{
	{0, 4, 1, 1}, {1, 4, 1, 1}, {2, 4, 1, 1}, {0, 3, 1, 1}, {3, 4, 1, 1}
}
frogger_death_anim_timer : f32 = get_anim_duration(frogger_death_anim_fps, len(frogger_death_anim_frames))



move_rectangles_with_uniform_speed_and_wrap :: proc(rectangles: []rl.Rectangle, speed, dt: f32)
{
	for &rectangle in rectangles
	{
		rectangle_move_amount := -2 * dt
		rectangle.x += rectangle_move_amount

		should_warp_to_right_side_of_screen := rectangle_move_amount < 0 && rectangle.x < -rectangle.width
		should_warp_to_left_side_of_screen := rectangle_move_amount > 0 && rectangle.x > f32(gmem.number_of_grid_cells_on_axis_x) + 1 

		if should_warp_to_right_side_of_screen
		{
			rectangle_overshoot_amount : f32 = rectangle.x + rectangle.width // -1.5 + 1 = -0.5 
			rectangle.x = (f32(gmem.number_of_grid_cells_on_axis_x) + rectangle.width) + rectangle_overshoot_amount
		}
		else if should_warp_to_left_side_of_screen 
		{
			rectangle_overshoot_amount : f32 = rectangle.x - f32(gmem.number_of_grid_cells_on_axis_x) + 1
			rectangle.x = 0 - rectangle.width - 1 + rectangle_overshoot_amount
		}
	}
}


move_entities_and_wrap :: proc(entities: []Entity, dt: f32)
{
	for &entity in entities
	{
		rectangle := &entity.rectangle
		rectangle_move_amount := entity.speed * dt
		rectangle.x += rectangle_move_amount

		should_warp_to_right_side_of_screen := rectangle_move_amount < 0 && rectangle.x < -rectangle.width - entity.warp_boundary_extension
		should_warp_to_left_side_of_screen := rectangle_move_amount > 0 && rectangle.x > f32(gmem.number_of_grid_cells_on_axis_x) + entity.warp_boundary_extension

		if should_warp_to_right_side_of_screen
		{
			rectangle_overshoot_amount : f32 = rectangle.x + rectangle.width + entity.warp_boundary_extension // -1.5 + 1 = -0.5 
			rectangle.x = (f32(gmem.number_of_grid_cells_on_axis_x) + rectangle.width) + rectangle_overshoot_amount
		}
		else if should_warp_to_left_side_of_screen 
		{
			rectangle_overshoot_amount : f32 = rectangle.x - f32(gmem.number_of_grid_cells_on_axis_x)
			rectangle.x = -rectangle.width + rectangle_overshoot_amount
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
@(export)
game_reset_entities :: proc(mem: ^Game_Memory)
{
	gmem.floating_logs = floating_logs[:]

	gmem.turtles = turtles[:]
	gmem.diving_turtles = diving_turtles[:]

	gmem.vehicles = vehicles[:]
	gmem.vehicles_speed = vehicles_speed[:]
	//gmem.vehicles_colors = vehicles_colors[:]
	gmem.vehicle_positions = vehicle_positions[:]
}

frogger_move_lerp_duration : f32 = 0.1


@(export)
game_init :: proc()
{
	cell_size : i32 = 64

	number_of_grid_cells_on_axis_x : i32 = 14
	number_of_grid_cells_on_axis_y : i32 = 16

	game_screen_width  : i32 = cell_size * number_of_grid_cells_on_axis_x
	game_screen_height : i32 = cell_size * number_of_grid_cells_on_axis_y

	game_render_target := rl.LoadRenderTexture(game_screen_width, game_screen_height)
	rl.SetTextureFilter(game_render_target.texture, rl.TextureFilter.BILINEAR)

	frogger_move_lerp_timer  := Timer {
		amount = frogger_move_lerp_duration,
		duration = frogger_move_lerp_duration,
	}

	frogger_move_lerp_start_pos : [2]f32
	frogger_move_lerp_end_pos   : [2]f32


	debug_show_grid := false
	is_frogger_unkillable := false

	gmem = new(Game_Memory)

	gmem.cell_size = f32(cell_size)
	gmem.number_of_grid_cells_on_axis_x = f32(number_of_grid_cells_on_axis_x)
	gmem.number_of_grid_cells_on_axis_y = f32(number_of_grid_cells_on_axis_y)

	gmem.initial_window_width = f32(initial_window_width)
	gmem.initial_window_height = f32(initial_window_height)
	gmem.game_render_target = game_render_target
	gmem.game_screen_width = f32(game_screen_width)
	gmem.game_screen_height = f32(game_screen_height)

	gmem.dbg_show_grid = debug_show_grid
	gmem.dbg_is_frogger_unkillable = is_frogger_unkillable

	gmem.frogger_pos = [2]f32{7,14}
	gmem.frogger_move_lerp_timer = frogger_move_lerp_timer
	gmem.frogger_move_lerp_start_pos = frogger_move_lerp_start_pos
	gmem.frogger_move_lerp_end_pos = frogger_move_lerp_end_pos

	gmem.is_frogs_on_lilypad = is_frogs_on_lilypad

	image_sprite_sheet := rl.LoadImageFromMemory(".png", &image_data_sprite_sheet[0], i32(len(image_data_sprite_sheet)))
	image_background   := rl.LoadImageFromMemory(".png", &image_data_background[0], i32(len(image_data_background)))

	gmem.texture_sprite_sheet = rl.LoadTextureFromImage(image_sprite_sheet)
	gmem.texture_background   = rl.LoadTextureFromImage(image_background)

	game_reset_entities(gmem)
}




get_anim_current_frame_index :: proc(t, fps: f32, number_of_frames: int) -> int
{
	ret := int(math.mod(t * fps, f32(number_of_frames)))
	return ret
}


get_anim_duration :: proc(fps: f32, number_of_frames: int) -> f32
{
	ret := f32(number_of_frames) / fps
	return ret
}


get_anim_current_frame_sprite_sheet_clip :: proc(t, fps: f32, frame_clips: []rl.Rectangle) -> rl.Rectangle
{
	frame_index := get_anim_current_frame_index(t, fps, len(frame_clips))
	frame_clip_rectangle := frame_clips[frame_index]
	return frame_clip_rectangle
}



@(export)
game_update :: proc()
{
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


	river := rl.Rectangle{0, 2, 14, 6}
	riverbed := rl.Rectangle{0, 1, 14,2}



	if !gmem.pause
	{	
		is_frogger_death_anim_playing := frogger_death_anim_timer < get_anim_duration(frogger_death_anim_fps, len(frogger_death_anim_frames))


		can_frogger_request_move := timer_is_complete(gmem.frogger_move_lerp_timer)  && !is_frogger_death_anim_playing 
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
				
				will_frogger_be_out_of_left_bounds :=  frogger_next_pos.x < 0 && frogger_move_direction.x == -1
				will_frogger_be_out_of_right_bounds := frogger_next_pos.x >= f32(gmem.number_of_grid_cells_on_axis_x) && frogger_move_direction.x == 1
				will_frogger_be_out_of_top_bounds := frogger_next_pos.y < 0 && frogger_move_direction.y == -1
				will_frogger_be_out_of_bottom_bounds := frogger_next_pos.y > gmem.number_of_grid_cells_on_axis_y - 2&& frogger_move_direction.y == 1
				
				will_frogger_be_out_of_bounds_on_next_move := will_frogger_be_out_of_left_bounds || 
					will_frogger_be_out_of_right_bounds || 
					will_frogger_be_out_of_top_bounds || 
					will_frogger_be_out_of_bottom_bounds


				if !will_frogger_be_out_of_bounds_on_next_move 
				{
					timer_start(&gmem.frogger_move_lerp_timer)
					gmem.frogger_move_lerp_start_pos = gmem.frogger_pos
					gmem.frogger_move_lerp_end_pos = frogger_next_pos
				}
			}
		}


		{ // lily
			log_that_lily_is_on := floating_logs[lily_logs_to_spawn_on[lily_log_to_spawn_on_index]]

			if timer_is_complete(lily_lerp_timer)
			{
				timer_advance(&lily_wait_timer, frame_time)
				if timer_is_complete(lily_wait_timer)
				{
					move_amount_x : f32 = 0 

					// FIXME(jblat): lily will jump to the edge again if she is on the edge
					if lily_direction == .Right
					{
						edge_of_log_x := log_that_lily_is_on.rectangle.width - 1
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

			// if timer_is_complete(lily_wait_timer) && timer_is_complete(lily_lerp_timer)
			// {
			// 	timer_start(&lily_lerp_timer)
			// }
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


		{ // frogger animation
			timer_advance(&frogger_anim_timer, frame_time)
		}


		{ // frogger death animation
			if is_frogger_death_anim_playing
			{
				frogger_death_anim_timer += frame_time
				frogger_death_animation_duration := get_anim_duration(frogger_death_anim_fps, len(frogger_death_anim_frames))
				frogger_death_anim_timer = min(frogger_death_animation_duration, frogger_death_anim_timer)
				is_death_animation_complete := frogger_death_anim_timer == frogger_death_animation_duration
				if is_death_animation_complete
				{
					gmem.frogger_pos = frogger_start_pos
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


		{ // fly 
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
				for gmem.is_frogs_on_lilypad[fly_lilypad_indices[fly_lilypad_index]]
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
			move_entities_and_wrap(gmem.floating_logs, frame_time)
			move_entities_and_wrap(gmem.turtles, frame_time)
			move_entities_and_wrap(gmem.diving_turtles, frame_time)
		}


		{ // move vehicles
			for &vehicle, i in gmem.vehicles 
			{
				vehicle_move_speed : f32 = gmem.vehicles_speed[i]
				vehicle_move_amount := vehicle_move_speed * frame_time
				vehicle.x += vehicle_move_amount

				should_warp_vehicle_to_right_side_of_screen := vehicle_move_amount < 0 && vehicle.x < 0 - vehicle.width
				should_warp_vehicle_to_left_side_of_screen := vehicle_move_amount > 0 && vehicle.x > f32(gmem.number_of_grid_cells_on_axis_x) + 1 

				if should_warp_vehicle_to_right_side_of_screen
				{
					overshoot_amount : f32 = vehicle.x + vehicle.width

					vehicle.x = f32(gmem.number_of_grid_cells_on_axis_x) + vehicle.width + overshoot_amount
				}
				else if should_warp_vehicle_to_left_side_of_screen 
				{
					vehicle.x = 0 - vehicle.width - 1
				}
			}
		}


		should_process_moving_frogger_with_intersecting_entities := !is_frogger_death_anim_playing 
		if should_process_moving_frogger_with_intersecting_entities
		{ 
			gmem.frogger_pos, gmem.frogger_move_lerp_end_pos = move_frogger_with_intersecting_entities(gmem.frogger_pos, gmem.frogger_move_lerp_end_pos, gmem.floating_logs, frame_time)
			gmem.frogger_pos, gmem.frogger_move_lerp_end_pos = move_frogger_with_intersecting_entities(gmem.frogger_pos, gmem.frogger_move_lerp_end_pos, gmem.turtles, frame_time)
			gmem.frogger_pos, gmem.frogger_move_lerp_end_pos = move_frogger_with_intersecting_entities(gmem.frogger_pos, gmem.frogger_move_lerp_end_pos, gmem.diving_turtles, frame_time)
		}


		should_check_for_win_condtions := !is_frogger_death_anim_playing
		if should_check_for_win_condtions 
		{
			for lilypad, i in lilypads 
			{	
				frogger_center_pos := gmem.frogger_pos + 0.5
				is_frogger_on_lilypad := rl.CheckCollisionPointRec(frogger_center_pos, lilypad)
				is_there_already_a_frog_here := gmem.is_frogs_on_lilypad[i]
				if is_frogger_on_lilypad && !is_there_already_a_frog_here
				{
					gmem.is_frogs_on_lilypad[i] = true
					gmem.frogger_pos = frogger_start_pos
					timer_stop(&gmem.frogger_move_lerp_timer)
					
					if fly_lilypad_indices[fly_lilypad_index] == i
					{
						gmem.score += 100
					}
				}
			}

			number_of_frogs_on_lilypad := 0
			for present in gmem.is_frogs_on_lilypad
			{
				if present
				{
					number_of_frogs_on_lilypad += 1
				}
			}

			is_all_frogs_on_lilypads := number_of_frogs_on_lilypad == len(gmem.is_frogs_on_lilypad)
			if is_all_frogs_on_lilypads
			{
				for &present in gmem.is_frogs_on_lilypad
				{
					present = false
				}
			}
		}


		should_check_for_game_over := !is_frogger_death_anim_playing
		if should_check_for_game_over 
		{
			is_frogger_out_of_bounds := gmem.frogger_pos.x + 0.5 < 0 || gmem.frogger_pos.x - 0.5 >= f32(gmem.number_of_grid_cells_on_axis_x) -1 || gmem.frogger_pos.y < 0 || gmem.frogger_pos.y > f32(gmem.number_of_grid_cells_on_axis_y)
			if is_frogger_out_of_bounds 
			{
				timer_stop(&gmem.frogger_move_lerp_timer)
				frogger_death_anim_timer = 0
			}

			frogger_center_pos := gmem.frogger_pos + 0.5
			for vehicle in gmem.vehicles
			{
				is_frogger_hit_by_vehicle := rl.CheckCollisionPointRec(frogger_center_pos, vehicle)
				if is_frogger_hit_by_vehicle
				{
					timer_stop(&gmem.frogger_move_lerp_timer)
					frogger_death_anim_timer = 0
				}
			}

			frogger_on_log := false
			is_frogger_moving := !timer_is_complete(gmem.frogger_move_lerp_timer)
			is_frogger_in_river_region := frogger_center_pos.y > river.y && frogger_center_pos.y < river.y + river.height
			is_frogger_in_riverbed := rl.CheckCollisionPointRec(frogger_center_pos, riverbed)

			did_frogger_collide_with_riverbed := is_frogger_in_riverbed
			if did_frogger_collide_with_riverbed
			{
				timer_stop(&gmem.frogger_move_lerp_timer)
				frogger_death_anim_timer = 0
			}

			for log in gmem.floating_logs
			{
				is_frogger_center_pos_inside_log_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, log.rectangle)				

				if is_frogger_center_pos_inside_log_rectangle
				{
					frogger_on_log = true
				}
			}

			for turtle in gmem.turtles
			{
				is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos,  turtle.rectangle)
				
				if is_frogger_center_pos_inside_turtle_rectangle
				{
					frogger_on_log = true
				}
			}

			for turtle, i in gmem.diving_turtles
			{
				is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos,  turtle.rectangle)
				anim_timer := diving_turtles_anim_timers[i]
				current_diving_turtle_frame := get_anim_current_frame_index(anim_timer, diving_turtles_anim_fps, len(diving_turtle_anim_frames))
				is_turtle_above_water := diving_turtle_underwater_frame != current_diving_turtle_frame
				if is_frogger_center_pos_inside_turtle_rectangle && is_turtle_above_water
				{
					frogger_on_log = true
				}
			}

			did_frogger_fall_in_river := !frogger_on_log && is_frogger_in_river_region

			if did_frogger_fall_in_river
			{
				timer_stop(&gmem.frogger_move_lerp_timer)
				frogger_death_anim_timer = 0
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
			scale : f32 =  gmem.cell_size / sprite_sheet_cell_size
			rl.DrawTextureEx(gmem.texture_background, [2]f32{0,0}, 0, scale, rl.WHITE)
		}

		{ // draw obstacles
			for log, i in gmem.floating_logs 
			{
				log_sprite_clip := floating_logs_sprite_clips[i]
				draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, log_sprite_clip, log.rectangle, sprite_sheet_cell_size, gmem.cell_size, 0)
			}

			for vehicle, i in gmem.vehicles
			{
				vehicle_sprite_sheet_clip := vehicle_sprite_sheet_clips[i]
				draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, vehicle_sprite_sheet_clip, vehicle, sprite_sheet_cell_size, gmem.cell_size, 0)
			}

			regular_turtles_current_frame_sprite_sheet_clip_rectangle := get_anim_current_frame_sprite_sheet_clip(regular_turtles_anim_timer, regular_turtles_anim_fps, regular_turtle_anim_frames[:])
			for turtle in gmem.turtles
			{
				draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, regular_turtles_current_frame_sprite_sheet_clip_rectangle, turtle.rectangle, sprite_sheet_cell_size, gmem.cell_size, 0)
			}


			for turtle, i in gmem.diving_turtles
			{
				anim_timer := diving_turtles_anim_timers[i]
				diving_turtles_current_frame_sprite_sheet_clilp_rectangle := get_anim_current_frame_sprite_sheet_clip(anim_timer, diving_turtles_anim_fps, diving_turtle_anim_frames[:])
				draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, diving_turtles_current_frame_sprite_sheet_clilp_rectangle, turtle.rectangle, sprite_sheet_cell_size, gmem.cell_size, 0)
			}

		}

		{ // draw frogger
			is_frogger_death_anim_playing := frogger_death_anim_timer < get_anim_duration(frogger_death_anim_fps, len(frogger_death_anim_frames))
			anim_timer    : f32 =    is_frogger_death_anim_playing ? frogger_death_anim_timer     : frogger_anim_timer.amount
			anim_fps      : f32 =    is_frogger_death_anim_playing ? frogger_death_anim_fps       : 12.0 
			frames :[]rl.Rectangle = is_frogger_death_anim_playing ? frogger_death_anim_frames[:] : frogger_anim_frames[:]
			rotation : f32         = is_frogger_death_anim_playing ? 0                            : gmem.frogger_sprite_rotation
			
			current_frame_sprite_sheet_clip_rectangle := get_anim_current_frame_sprite_sheet_clip(anim_timer, anim_fps, frames)
			rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}
			draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, current_frame_sprite_sheet_clip_rectangle, rectangle, sprite_sheet_cell_size, gmem.cell_size, rotation)
		}

		{ // draw lily
			log_that_lily_is_on := lily_logs_to_spawn_on[lily_log_to_spawn_on_index]
			log := floating_logs[log_that_lily_is_on]
			lily_world_rectangle := rl.Rectangle{
				log.rectangle.x + lily_relative_log_pos_x,
				log.rectangle.y,
				lily_width,
				lily_height
			}
			rotation := map_direction_rotation[lily_direction]
			draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, lily_sprite_sheet_clip, lily_world_rectangle, sprite_sheet_cell_size, gmem.cell_size, rotation)
		}

		{ // draw fly
			clip := fly_is_active ? fly_sprite_sheet_clip : rl.Rectangle {}
			lilypad_index := fly_lilypad_indices[fly_lilypad_index%len(fly_lilypad_indices)]
			dst_rect := lilypads[lilypad_index]
			draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, clip, dst_rect, sprite_sheet_cell_size, gmem.cell_size, 0)
		}
 
		{ // draw frogs on lilypads
			for lp, i in lilypads
			{	
				is_there_a_frog_on_this_lilypad := gmem.is_frogs_on_lilypad[i]
				if is_there_a_frog_on_this_lilypad
				{
					draw_sprite_sheet_rectangle_clip_on_grid(gmem.texture_sprite_sheet, happy_frog_sprite_clip_closed_mouth, lp, sprite_sheet_cell_size, gmem.cell_size, 0)
				}
			}
		}

	
		if gmem.dbg_show_grid 
		{ 	
			for x : f32 = 0; x < gmem.number_of_grid_cells_on_axis_x; x += 1 
			{
				render_x := x * gmem.cell_size
				render_start_y : f32 = 0
				render_end_y := gmem.game_screen_height
				rl.DrawLineV([2]f32{render_x, render_start_y}, [2]f32{render_x, render_end_y}, rl.WHITE)
			}

			for y : f32 = 0; y < gmem.number_of_grid_cells_on_axis_y; y += 1 
			{
				render_y := y * gmem.cell_size
				render_start_x : f32 = 0
				render_end_x := gmem.game_screen_width 
				rl.DrawLineV([2]f32{render_start_x, render_y}, [2]f32{render_end_x, render_y}, rl.WHITE)
			}
		}

		if gmem.dbg_show_entity_bounding_rectangles
		{	
			frogger_rectangle := rl.Rectangle{gmem.frogger_pos.x, gmem.frogger_pos.y, 1, 1}
			draw_rectangle_lines_on_grid(frogger_rectangle, 4, rl.GREEN, gmem.cell_size)

			// TODO(jblat): draw the rest of the stuff like logs and whatnot
		}			
	}

	{ // DRAW TO WINDOW
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		src := rl.Rectangle{ 0, 0, f32(gmem.game_render_target.texture.width), f32(-gmem.game_render_target.texture.height) }
		
		scale := min(screen_width/gmem.game_screen_width, screen_height/gmem.game_screen_height)

		window_scaled_width  := gmem.game_screen_width  * scale
		window_scaled_height := gmem.game_screen_height * scale

		dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}
		rl.DrawTexturePro(gmem.game_render_target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)
	}

}