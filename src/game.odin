package game

import rl "vendor:raylib"
import "core:math"

image_data_sprite_sheet := #load("frogger_sprite_sheet.png")
image_data_background   := #load("frogger_background_modified.png")

sprite_sheet_cell_size : f32 = 16




Entity :: struct
{
	rectangle : rl.Rectangle,
	speed     : f32,
	color     : rl.Color,
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
	frogger_move_lerp_timer     : f32,
	frogger_move_lerp_start_pos : [2]f32,
	frogger_move_lerp_end_pos   : [2]f32,

	frogger_sprite_rotation: f32,

	// win
	is_frogs_on_lilypad :[5]bool,

	// entities
	floating_logs :[][4]f32,
	floating_logs_speed :[]f32,

	turtles :[][4]f32,
	turtles_speed :[]f32,

	vehicles :[][4]f32,
	vehicles_speed :[]f32,
	vehicles_colors :[]rl.Color,
}


gmem: ^Game_Memory


lilypad_end_goals := [5]rl.Rectangle{
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

is_frogs_on_lilypad := [5]bool{}

floating_logs := [?][4]f32{
	{0, 3,  4, 1},
	{6, 3,  4, 1},
	{13, 3, 4, 1},

	{0, 5, 6, 1},
	{9, 5, 6, 1},
	

	{0,  6, 3, 1},
	{11, 6, 3, 1}
}

floating_logs_speed := [?]f32{
	2,
	2,
	2,

	3,
	3,

	1,
	1,
}

turtles := [?][4]f32 {
	{0, 7, 1, 1}, {1, 7, 1, 1}, {2,  7, 1, 1},
	{4, 7, 1, 1}, {5, 7, 1, 1}, {6,  7, 1, 1},
	{8, 7, 1, 1}, {9, 7, 1, 1}, {10, 7, 1, 1},

	{2,  4, 1, 1}, {3,  4, 1, 1},
	{6,  4, 1, 1}, {7,  4, 1, 1},
	{10, 4, 1, 1}, {11, 4, 1, 1},
	{14, 4, 1, 1}, {15, 4, 1, 1},

}

turtles_speed := [?]f32 {
	-2, -2, -2,
	-2, -2, -2,
	-2, -2, -2,

	-2, -2, 
	-2, -2, 
	-2, -2, 
	-2, -2, 
}


vehicles := [?][4]f32{
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

	-2,
	-2,
}

vehicles_colors := [?]rl.Color{
	rl.YELLOW,
	rl.YELLOW,
	rl.YELLOW,

	rl.WHITE,
	rl.WHITE,
	rl.WHITE,

	rl.VIOLET,
	rl.VIOLET,
	rl.VIOLET,

	rl.RED,
	rl.RED,
	rl.RED,

	rl.LIGHTGRAY,
	rl.LIGHTGRAY,
}


// Note(jblat): This will make sure that if the above entities change,
// They will actually be reset
@(export)
game_reset_entities :: proc(mem: ^Game_Memory)
{
	gmem.floating_logs = floating_logs[:]
	gmem.floating_logs_speed = floating_logs_speed[:]

	gmem.turtles = turtles[:]
	gmem.turtles_speed = turtles_speed[:]

	gmem.vehicles = vehicles[:]
	gmem.vehicles_speed = vehicles_speed[:]
	gmem.vehicles_colors = vehicles_colors[:]
}


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

	frogger_move_lerp_timer  : f32 = 0
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


frogger_anim_duration : f32 = 0.25
frogger_anim_timer : f32 = frogger_anim_duration


@(export)
game_update :: proc()
{
	frame_time_uncapped := rl.GetFrameTime()
	frame_time := min(frame_time_uncapped, f32(1.0/60.0))

	frogger_start_pos := [2]f32{7,14}
	frogger_move_lerp_duration : f32 = 0.08

	frogger_anim_frames := [?][2]f32{
		{0,0}, {1,0}, {0,0}, {2,0}
	}

	river := rl.Rectangle{0, 2, 14, 6}
	riverbed := rl.Rectangle{0, 0, 14,2}

	can_frogger_request_move := gmem.frogger_move_lerp_timer <= 0 

	if can_frogger_request_move  
	{
		frogger_move_direction := [2]f32{0,0}

		if rl.IsKeyPressed(.LEFT) 
		{
			frogger_move_direction.x = -1
			gmem.frogger_sprite_rotation  = 270

			frogger_anim_timer = 0
		} 
		else if rl.IsKeyPressed(.RIGHT) 
		{
			frogger_move_direction.x = 1
			gmem.frogger_sprite_rotation = 90
			frogger_anim_timer = 0

		} 
		else if rl.IsKeyPressed(.UP) 
		{
			frogger_move_direction.y = -1
			gmem.frogger_sprite_rotation = 0
			frogger_anim_timer = 0

		} 
		else if rl.IsKeyPressed(.DOWN) 
		{
			frogger_move_direction.y = 1
			gmem.frogger_sprite_rotation = 180
			frogger_anim_timer = 0
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
				gmem.frogger_move_lerp_timer = frogger_move_lerp_duration
				gmem.frogger_move_lerp_start_pos = gmem.frogger_pos
				gmem.frogger_move_lerp_end_pos = frogger_next_pos
			}

			// TODO(jblat): make it so that frogger can't move out of bounds to a point where he would die

		}
	} 
	else 
	{
		gmem.frogger_move_lerp_timer -= frame_time
		t := 1.0 - gmem.frogger_move_lerp_timer / frogger_move_lerp_duration
		if t >= 1.0 
		{
			t = 1.0
		}
		gmem.frogger_pos.x = (1.0 - t) * gmem.frogger_move_lerp_start_pos.x + t * gmem.frogger_move_lerp_end_pos.x
		gmem.frogger_pos.y = (1.0 - t) * gmem.frogger_move_lerp_start_pos.y + t * gmem.frogger_move_lerp_end_pos.y
	}

	{ // frogger animation
		is_frogger_animation_complete := frogger_anim_timer >= frogger_anim_duration
		if !is_frogger_animation_complete
		{
			frogger_anim_timer += frame_time
			frogger_anim_timer = min(frogger_anim_duration, frogger_anim_timer)
		}
	}

	{ // move logs
		for &log, i in gmem.floating_logs 
		{
			log_move_speed : f32 = gmem.floating_logs_speed[i]
			log_move_amount := log_move_speed * frame_time
			log.x += log_move_amount
			if log.x > f32(gmem.number_of_grid_cells_on_axis_x) + 1 
			{
				log.x = 0 - log[2] - 1
			}
		}
	}

	{ // move vehicles
		for &vehicle, i in gmem.vehicles 
		{
			vehicle_move_speed : f32 = gmem.vehicles_speed[i]
			vehicle_move_amount := vehicle_move_speed * frame_time
			vehicle.x += vehicle_move_amount

			should_warp_vehicle_to_right_side_of_screen := vehicle_move_amount < 0 && vehicle.x < 0 - vehicle[2]
			should_warp_vehicle_to_left_side_of_screen := vehicle_move_amount > 0 && vehicle.x > f32(gmem.number_of_grid_cells_on_axis_x) + 1 

			if should_warp_vehicle_to_right_side_of_screen
			{
				vehicle.x = f32(gmem.number_of_grid_cells_on_axis_x) + vehicle[2]
			}
			else if should_warp_vehicle_to_left_side_of_screen 
			{
				vehicle.x = 0 - vehicle[2] - 1
			}
		}
	}

	{ // turtles
		for &turtle, i in gmem.turtles
		{
			turtle_move_speed : f32 = gmem.turtles_speed[i]
			turtle_move_amount := turtle_move_speed * frame_time
			turtle.x += turtle_move_amount

			should_warp_to_right_side_of_screen := turtle_move_amount < 0 && turtle.x < -turtle[2]
			should_warp_to_left_side_of_screen := turtle_move_amount > 0 && turtle.x > f32(gmem.number_of_grid_cells_on_axis_x) + 1 

			if should_warp_to_right_side_of_screen
			{
				turtle_overshoot_amount : f32 = turtle.x + turtle[2] // -1.5 + 1 = -0.5 
				turtle.x = (f32(gmem.number_of_grid_cells_on_axis_x) + turtle[2]) + turtle_overshoot_amount
			}
			else if should_warp_to_left_side_of_screen 
			{
				turtle.x = 0 - turtle[2] - 1
			}
		}
	}

	{ // move frogger if center is on log or turtles
		frogger_center_pos := [2]f32{gmem.frogger_pos.x + 0.5, gmem.frogger_pos.y + 0.5}
		for log, i in gmem.floating_logs 
		{
			is_frogger_center_pos_inside_log_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) log)
			should_frogger_move_with_log := is_frogger_center_pos_inside_log_rectangle 
			
			if should_frogger_move_with_log 
			{
				log_move_speed : f32 = gmem.floating_logs_speed[i]
				log_move_amount := log_move_speed * frame_time
				gmem.frogger_pos.x += log_move_amount
				gmem.frogger_move_lerp_end_pos.x += log_move_amount

			}
		}

		for turtle, i in gmem.turtles 
		{
			is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) turtle)
			should_frogger_move_with_turtle := is_frogger_center_pos_inside_turtle_rectangle 
			
			if should_frogger_move_with_turtle 
			{
				turtle_move_speed : f32 = gmem.turtles_speed[i]
				turtle_move_amount := turtle_move_speed * frame_time
				gmem.frogger_pos.x += turtle_move_amount
				gmem.frogger_move_lerp_end_pos.x += turtle_move_amount

			}
		}
	}

	{ // win conditions
		for lp, i in lilypad_end_goals 
		{	
			frogger_center_pos := gmem.frogger_pos + 0.5
			is_frogger_on_lilypad := rl.CheckCollisionPointRec(frogger_center_pos, lp)
			is_there_already_a_frog_here := gmem.is_frogs_on_lilypad[i]
			if is_frogger_on_lilypad && !is_there_already_a_frog_here
			{
				gmem.is_frogs_on_lilypad[i] = true
				gmem.frogger_pos = frogger_start_pos
			}
		}
	}

	{ // game over
		is_frogger_out_of_bounds := gmem.frogger_pos.x < -1 || gmem.frogger_pos.x >= f32(gmem.number_of_grid_cells_on_axis_x) || gmem.frogger_pos.y < 0 || gmem.frogger_pos.y > f32(gmem.number_of_grid_cells_on_axis_y)
		if is_frogger_out_of_bounds 
		{
			gmem.frogger_pos = frogger_start_pos
		}

		frogger_center_pos := gmem.frogger_pos + 0.5
		for vehicle in gmem.vehicles
		{
			vehicle_rect := transmute(rl.Rectangle)vehicle
			is_frogger_hit_by_vehicle := rl.CheckCollisionPointRec(frogger_center_pos, vehicle_rect)
			if is_frogger_hit_by_vehicle
			{
				gmem.frogger_pos = frogger_start_pos
			}
		}

		frogger_on_log := false
		frogger_on_turtle := false
		is_frogger_moving := gmem.frogger_move_lerp_timer > 0
		river_rect := transmute(rl.Rectangle)river
		is_frogger_in_river_region := frogger_center_pos.y >= river_rect.y && frogger_center_pos.y <= river_rect.y + river_rect.height
		is_frogger_in_riverbed := rl.CheckCollisionPointRec(frogger_center_pos, riverbed)

		is_frogger_die_in_riverbed := is_frogger_in_riverbed && !is_frogger_moving
		if is_frogger_die_in_riverbed
		{
			gmem.frogger_pos = frogger_start_pos
		}

		for log in gmem.floating_logs
		{
			is_frogger_center_pos_inside_log_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) log)				

			if is_frogger_center_pos_inside_log_rectangle
			{
				frogger_on_log = true
			}
		}

		for turtle in gmem.turtles
		{
			is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) turtle)
			
			if is_frogger_center_pos_inside_turtle_rectangle
			{
				frogger_on_log = true
			}
		}

		did_frogger_fall_in_river := !frogger_on_log && !frogger_on_turtle && is_frogger_in_river_region && !is_frogger_moving

		if did_frogger_fall_in_river
		{
			gmem.frogger_pos = frogger_start_pos
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
			for log in gmem.floating_logs 
			{
				log_with_padding := log
				log_with_padding.y += 0.1
				log_with_padding[3] -= 0.2
				log_rectangle := log_with_padding * gmem.cell_size
				rl.DrawRectangleRec(transmute(rl.Rectangle)log_rectangle, rl.BROWN)
			}

			for vehicle, i in gmem.vehicles
			{
				vehicle_with_padding := vehicle
				vehicle_with_padding.y += 0.1
				vehicle_with_padding[3] -= 0.2
				vehicle_rectangle := vehicle_with_padding * gmem.cell_size
				vehicle_color := gmem.vehicles_colors[i]
				rl.DrawRectangleRec(transmute(rl.Rectangle)vehicle_rectangle, vehicle_color)
			}

			for turtle in gmem.turtles
			{
				turtle_with_padding := turtle
				turtle_with_padding.x += 0.1
				turtle_with_padding.y += 0.1
				turtle_with_padding[2] -= 0.2
				turtle_with_padding[3] -= 0.2
				turtle_rectangle := turtle_with_padding * gmem.cell_size
				turtle_color := rl.ORANGE
				rl.DrawRectangleRec(transmute(rl.Rectangle)turtle_rectangle, turtle_color)
			}
		}

		{ // draw frogger
			frogger_anim_current_frame := int(( frogger_anim_timer / frogger_anim_duration ) * len(frogger_anim_frames))
			frogger_anim_current_frame = min(frogger_anim_current_frame, len(frogger_anim_frames) - 1)
			frogger_sprite_src_pos := frogger_anim_frames[frogger_anim_current_frame]
			draw_sprite_sheet_clip_on_grid(gmem.texture_sprite_sheet, frogger_sprite_src_pos, gmem.frogger_pos, sprite_sheet_cell_size, gmem.cell_size, gmem.frogger_sprite_rotation)
		}

		{ // draw frogs on lilypads
			for lp, i in lilypad_end_goals
			{	
				is_there_a_frog_on_this_lilypad := gmem.is_frogs_on_lilypad[i]
				if is_there_a_frog_on_this_lilypad
				{
					frog_rectangle := lp
					frog_rectangle.x += 0.1
					frog_rectangle.y += 0.1
					frog_rectangle.width  -= 0.2
					frog_rectangle.height -= 0.2

					draw_rectangle_on_grid(frog_rectangle, rl.GREEN, gmem.cell_size)
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