package main

import rl "vendor:raylib"

// https://forum.sublimetext.com/t/my-sublime-text-windows-cheat-sheet/8411




main :: proc () {

	// All positions and dimensions will be driven by the grid and then scaled however much is needed
	cell_size : i32 = 64

	number_of_grid_cells_on_axis_x : i32 = 14
	number_of_grid_cells_on_axis_y : i32 = 14

	initial_window_width := 640
	initial_window_height := 640

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(i32(initial_window_width), i32(initial_window_height), "Frogger [For Educational Purposes Only]")
	rl.SetTargetFPS(60)

	game_screen_width  : i32 = cell_size * number_of_grid_cells_on_axis_x
	game_screen_height : i32 = cell_size * number_of_grid_cells_on_axis_y

	game_render_target := rl.LoadRenderTexture(game_screen_width, game_screen_height)
	rl.SetTextureFilter(game_render_target.texture, rl.TextureFilter.BILINEAR)

	frogger_start_pos := [2]f32{7,7}
	frogger_pos := frogger_start_pos
	frogger_move_lerp_timer  : f32 = 0
	frogger_move_lerp_duration   : f32 = 0.06
	frogger_move_lerp_start_pos : [2]f32
	frogger_move_lerp_end_pos   : [2]f32

	lilypad_end_goal_positions := [5][2]f32{
		{.5,  1},
		{3.5,  1},
		{6.5,  1},
		{9.5, 1},
		{12.5, 1},
	}

	floating_logs := [?][4]f32{
		{0, 2,  4, 1},
		{6, 2,  4, 1},
		{13, 2, 4, 1},

		{0, 4, 6, 1},
		{9, 4, 6, 1},
		

		{0,  5, 3, 1},
		{11, 5, 3, 1}
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
		{0, 6, 1, 1}, {1, 6, 1, 1}, {2,  6, 1, 1},
		{4, 6, 1, 1}, {5, 6, 1, 1}, {6,  6, 1, 1},
		{8, 6, 1, 1}, {9, 6, 1, 1}, {10, 6, 1, 1},

		{2, 3, 1, 1}, {3, 3, 1, 1},
		{6, 3, 1, 1}, {7, 3, 1, 1},
		{10, 3, 1, 1}, {11, 3, 1, 1},
		{14, 3, 1, 1}, {15, 3, 1, 1},

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
		{10, 12, 1, 1},
		{6,  12, 1, 1},
		{2,  12, 1, 1},

		{5,  11, 1, 1},
		{9,  11, 1, 1},
		{13, 11, 1, 1 },
		
		{10, 10, 1, 1},
		{6,  10, 1, 1},
		{2,  10, 1, 1},

		{1, 9, 1, 1},
		{5, 9, 1, 1},
		{9, 9, 1, 1},

		{1, 8, 2, 1},
		{6, 8, 2, 1},
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

	river := [4]f32{0, 2, 14, 5}

	debug_show_grid := false


	for !rl.WindowShouldClose() 
	{
		
		// gameplay

		can_frogger_request_move := frogger_move_lerp_timer <= 0 

		if can_frogger_request_move  
		{
			frogger_move_direction := [2]f32{0,0}

			if rl.IsKeyPressed(.LEFT) 
			{
				frogger_move_direction.x = -1
			} 
			else if rl.IsKeyPressed(.RIGHT) 
			{
				frogger_move_direction.x = 1
			} 
			else if rl.IsKeyPressed(.UP) 
			{
				frogger_move_direction.y = -1
			} 
			else if rl.IsKeyPressed(.DOWN) 
			{
				frogger_move_direction.y = 1
			}

			did_frogger_request_move := frogger_move_direction != [2]f32{0,0}

			if did_frogger_request_move 
			{
				frogger_next_pos := frogger_pos + frogger_move_direction
				
				will_frogger_be_out_of_bounds_on_next_move := frogger_next_pos.x < 0 || frogger_next_pos.x >= f32(number_of_grid_cells_on_axis_x) || frogger_next_pos.y < 0 || frogger_next_pos.y > f32(number_of_grid_cells_on_axis_y)


				if !will_frogger_be_out_of_bounds_on_next_move 
				{
					frogger_move_lerp_timer = frogger_move_lerp_duration
					frogger_move_lerp_start_pos = frogger_pos
					frogger_move_lerp_end_pos = frogger_next_pos
				}

				// TODO(jblat): make it so that frogger can't move out of bounds to a point where he would die

			}
		} 
		else 
		{
			frogger_move_lerp_timer -= rl.GetFrameTime()
			t := 1.0 - frogger_move_lerp_timer / frogger_move_lerp_duration
			if t >= 1.0 
			{
				t = 1.0
			}
			frogger_pos.x = (1.0 - t) * frogger_move_lerp_start_pos.x + t * frogger_move_lerp_end_pos.x
			frogger_pos.y = (1.0 - t) * frogger_move_lerp_start_pos.y + t * frogger_move_lerp_end_pos.y
		}

		{ // move logs
			for &log, i in floating_logs 
			{
				log_move_speed : f32 = floating_logs_speed[i]
				log_move_amount := log_move_speed * rl.GetFrameTime()
				log.x += log_move_amount
				if log.x > f32(number_of_grid_cells_on_axis_x) + 1 {
					log.x = 0 - log[2] - 1
				}
			}
		}

		{ // move vehicles
			for &vehicle, i in vehicles 
			{
				vehicle_move_speed : f32 = vehicles_speed[i]
				vehicle_move_amount := vehicle_move_speed * rl.GetFrameTime()
				vehicle.x += vehicle_move_amount

				should_warp_vehicle_to_right_side_of_screen := vehicle_move_amount < 0 && vehicle.x < 0 - vehicle[2]
				should_warp_vehicle_to_left_side_of_screen := vehicle_move_amount > 0 && vehicle.x > f32(number_of_grid_cells_on_axis_x) + 1 

				if should_warp_vehicle_to_right_side_of_screen
				{
					vehicle.x = f32(number_of_grid_cells_on_axis_x) + vehicle[2]
				}
				else if should_warp_vehicle_to_left_side_of_screen 
				{
					vehicle.x = 0 - vehicle[2] - 1
				}
			}
		}

		{
			for &turtle, i in turtles
			{
				turtle_move_speed : f32 = turtles_speed[i]
				turtle_move_amount := turtle_move_speed * rl.GetFrameTime()
				turtle.x += turtle_move_amount

				should_warp_to_right_side_of_screen := turtle_move_amount < 0 && turtle.x < 0 - turtle[2]
				should_warp_to_left_side_of_screen := turtle_move_amount > 0 && turtle.x > f32(number_of_grid_cells_on_axis_x) + 1 

				if should_warp_to_right_side_of_screen
				{
					turtle.x = f32(number_of_grid_cells_on_axis_x) + turtle[2]
				}
				else if should_warp_to_left_side_of_screen 
				{
					turtle.x = 0 - turtle[2] - 1
				}
			}
		}

		{ // move frogger if center is on log or turtles
			frogger_center_pos := [2]f32{frogger_pos.x + 0.5, frogger_pos.y + 0.5}
			for log, i in floating_logs {
				is_frogger_center_pos_inside_log_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) log)
				is_frogger_moving := frogger_move_lerp_timer > 0
				should_frogger_move_with_log := !is_frogger_moving && is_frogger_center_pos_inside_log_rectangle 
				
				if should_frogger_move_with_log {
					log_move_speed : f32 = floating_logs_speed[i]
					log_move_amount := log_move_speed * rl.GetFrameTime()
					frogger_pos.x += log_move_amount
				}
			}

			for turtle, i in turtles {
				is_frogger_center_pos_inside_turtle_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) turtle)
				is_frogger_moving := frogger_move_lerp_timer > 0
				should_frogger_move_with_turtle := !is_frogger_moving && is_frogger_center_pos_inside_turtle_rectangle 
				
				if should_frogger_move_with_turtle {
					turtle_move_speed : f32 = turtles_speed[i]
					turtle_move_amount := turtle_move_speed * rl.GetFrameTime()
					frogger_pos.x += turtle_move_amount
				}
			}
		}

		{ // game over
			is_frogger_out_of_bounds := frogger_pos.x < 0 || frogger_pos.x >= f32(number_of_grid_cells_on_axis_x) || frogger_pos.y < 0 || frogger_pos.y > f32(number_of_grid_cells_on_axis_y)
			if is_frogger_out_of_bounds {
				frogger_pos = frogger_start_pos
			}

			frogger_center_pos := frogger_pos + 0.5
			for vehicle in vehicles
			{
				vehicle_rect := transmute(rl.Rectangle)vehicle
				is_frogger_hit_by_vehicle := rl.CheckCollisionPointRec(frogger_center_pos, vehicle_rect)
				if is_frogger_hit_by_vehicle
				{
					frogger_pos = frogger_start_pos
				}
			}

			frogger_on_log := false
			frogger_on_turtle := false
			is_frogger_moving := frogger_move_lerp_timer > 0
			river_rect := transmute(rl.Rectangle)river
			is_frogger_in_river_region := rl.CheckCollisionPointRec(frogger_center_pos, river_rect)	

			for log in floating_logs
			{
				is_frogger_center_pos_inside_log_rectangle := rl.CheckCollisionPointRec(frogger_center_pos, transmute(rl.Rectangle) log)				

				if is_frogger_center_pos_inside_log_rectangle
				{
					frogger_on_log = true
				}
			}

			for turtle in turtles
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
				frogger_pos = frogger_start_pos
			}
		}


		// debug options
		if rl.IsKeyPressed(.F1) 
		{
			debug_show_grid = !debug_show_grid
		}


		// rendering

		screen_width := f32(rl.GetScreenWidth())
		screen_height := f32(rl.GetScreenHeight())

		scale := min(screen_width/f32(game_screen_width), screen_height/f32(game_screen_height))

		// NOTE(jblat): For mouse, see: https://github.com/raysan5/raylib/blob/master/examples/core/core_window_letterbox.c

		{ // DRAW TO RENDER TEXTURE
			rl.BeginTextureMode(game_render_target)
			defer rl.EndTextureMode()

			rl.ClearBackground(rl.LIGHTGRAY) 

			{ // draw background art
				sidewalks := [2][4]f32{
					{ 0, 13, 14, 1 },
					{ 0, 7,  14, 1 }
				}
				road     := [4]f32{0, 8, 14, 5}
				riverbed := [4]f32{0, 0, 14,2}
				lilypads := [5][4]f32{}

				for lilypad_position, i in lilypad_end_goal_positions 
				{
					lilypads[i] = [4]f32{lilypad_position.x, lilypad_position.y, 1, 1}
				}

				for sw in sidewalks 
				{
					sw_rectangle := sw * f32(cell_size)
					rl.DrawRectangleRec(transmute(rl.Rectangle)sw_rectangle, rl.PURPLE)
				}

				road_rectangle     := road * f32(cell_size)
				river_rectangle    := river * f32(cell_size)
				riverbed_rectangle := riverbed * f32(cell_size)

				rl.DrawRectangleRec(transmute(rl.Rectangle)road_rectangle, rl.BLACK)
				rl.DrawRectangleRec(transmute(rl.Rectangle)river_rectangle, rl.BLUE)
				rl.DrawRectangleRec(transmute(rl.Rectangle)riverbed_rectangle, rl.LIME)

				for lp in lilypads 
				{
					lp_rectangle := lp * f32(cell_size)
					rl.DrawRectangleRec(transmute(rl.Rectangle)lp_rectangle, rl.DARKPURPLE)
				}
			}

			{ // draw obstacles
				for log in floating_logs 
				{
					log_with_padding := log
					log_with_padding.y += 0.1
					log_with_padding[3] -= 0.2
					log_rectangle := log_with_padding * f32(cell_size)
					rl.DrawRectangleRec(transmute(rl.Rectangle)log_rectangle, rl.BROWN)
				}

				for vehicle, i in vehicles
				{
					vehicle_with_padding := vehicle
					vehicle_with_padding.y += 0.1
					vehicle_with_padding[3] -= 0.2
					vehicle_rectangle := vehicle_with_padding * f32(cell_size)
					vehicle_color := vehicles_colors[i]
					rl.DrawRectangleRec(transmute(rl.Rectangle)vehicle_rectangle, vehicle_color)
				}

				for turtle in turtles
				{
					turtle_with_padding := turtle
					turtle_with_padding.x += 0.1
					turtle_with_padding.y += 0.1
					turtle_with_padding[2] -= 0.2
					turtle_with_padding[3] -= 0.2
					turtle_rectangle := turtle_with_padding * f32(cell_size)
					turtle_color := rl.ORANGE
					rl.DrawRectangleRec(transmute(rl.Rectangle)turtle_rectangle, turtle_color)
				}
			}

			{ // draw frogger
				frogger_cell_rectangle := [4]f32{frogger_pos.x, frogger_pos.y, 1, 1}
				frogger_cell_rectangle.x += 0.1
				frogger_cell_rectangle[2] -= 0.2
				frogger_cell_rectangle.y += 0.1
				frogger_cell_rectangle[3] -= 0.2

				frogger_rectangle := frogger_cell_rectangle * f32(cell_size)
				rl.DrawRectangleRec(transmute(rl.Rectangle)frogger_rectangle, rl.GREEN)
				rl.DrawRectangleLinesEx(transmute(rl.Rectangle)frogger_rectangle, 4, rl.DARKGREEN)
			}
	
			if debug_show_grid 
			{ 
				// draw grid
				
				for x : i32 = 0; x < number_of_grid_cells_on_axis_x; x += 1 
				{
					render_x := f32(x * cell_size)
					render_start_y : f32 = 0
					render_end_y := f32(game_screen_height)
					rl.DrawLineV([2]f32{render_x, render_start_y}, [2]f32{render_x, render_end_y}, rl.BLACK)
				}

				for y : i32 = 0; y < number_of_grid_cells_on_axis_y; y += 1 
				{
					render_y := f32(y * cell_size)
					render_start_x : f32 = 0
					render_end_x := f32(game_screen_width)
					rl.DrawLineV([2]f32{render_start_x, render_y}, [2]f32{render_end_x, render_y}, rl.BLACK)
				}

			}			
		}

		{ // DRAW TO WINDOW
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.BLACK)

			src := rl.Rectangle{ 0, 0, f32(game_render_target.texture.width), f32(-game_render_target.texture.height) }
			
			window_midpoint_x    := screen_width -  (f32(game_screen_width)   * scale) / 2
			window_midpoint_y    := screen_height - (f32(game_screen_height)  * scale) / 2
			window_scaled_width  := f32(game_screen_width)  * scale
			window_scaled_height := f32(game_screen_height) * scale

			dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}
			rl.DrawTexturePro(game_render_target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)
		}

	}

}