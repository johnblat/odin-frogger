package main

import rl "vendor:raylib"

// https://forum.sublimetext.com/t/my-sublime-text-windows-cheat-sheet/8411

main :: proc () {

	// Everything will be driven by the grid 
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

	target := rl.LoadRenderTexture(game_screen_width, game_screen_height)
	rl.SetTextureFilter(target.texture, rl.TextureFilter.BILINEAR)



	frogger_start_pos := [2]f32{7,13}
	frogger_pos := frogger_start_pos
	frogger_move_lerp_timer  : f32 = 0
	frogger_move_lerp_duration   : f32 = 0.06
	frogger_move_lerp_start_pos : [2]f32
	frogger_move_lerp_end_pos   : [2]f32

	end_goal_positions := [5][2]f32{
		{.5,  1},
		{3.5,  1},
		{6.5,  1},
		{9.5, 1},
		{12.5, 1},
	}

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

			}
		} 
		else 
		{
			frogger_move_lerp_timer -= rl.GetFrameTime()
			t := 1.0 - frogger_move_lerp_timer / frogger_move_lerp_duration
			if t >= 1.0 {
				t = 1.0
			}
			frogger_pos.x = (1.0 - t) * frogger_move_lerp_start_pos.x + t * frogger_move_lerp_end_pos.x
			frogger_pos.y = (1.0 - t) * frogger_move_lerp_start_pos.y + t * frogger_move_lerp_end_pos.y
		}
		

		// debug options
		if rl.IsKeyPressed(.F1) {
			debug_show_grid = true
		}


		// rendering

		screen_width := f32(rl.GetScreenWidth())
		screen_height := f32(rl.GetScreenHeight())

		scale := min(screen_width/f32(game_screen_width), screen_height/f32(game_screen_height))

		// NOTE(jblat): For mouse, see: https://github.com/raysan5/raylib/blob/master/examples/core/core_window_letterbox.c

		{ // DRAW TO RENDER TEXTURE
			rl.BeginTextureMode(target)
			defer rl.EndTextureMode()

			rl.ClearBackground(rl.LIGHTGRAY) 

			{ // draw background art
				sidewalks := [2][4]f32{
					{0, 13, 14, 1},
					{0, 7, 14, 1 }
				}
				road := [4]f32{0, 8, 14, 5}
				river := [4]f32{0, 2, 14, 5}
				riverbed := [4]f32{0, 0, 14,2}
				end_goals := [5][4]f32{}

				for end_goal_position, i in end_goal_positions {
					end_goals[i] = [4]f32{end_goal_position.x, end_goal_position.y, 1, 1}
				}

				for sw in sidewalks {
					sw_rectangle := sw * f32(cell_size)
					rl.DrawRectangleRec(transmute(rl.Rectangle)sw_rectangle, rl.PURPLE)
				}

				road_rectangle := road * f32(cell_size)
				river_rectangle := river * f32(cell_size)
				riverbed_rectangle := riverbed * f32(cell_size)

				rl.DrawRectangleRec(transmute(rl.Rectangle)road_rectangle, rl.BLACK)
				rl.DrawRectangleRec(transmute(rl.Rectangle)river_rectangle, rl.BLUE)
				rl.DrawRectangleRec(transmute(rl.Rectangle)riverbed_rectangle, rl.LIME)

				for eg in end_goals {
					eg_rectangle := eg * f32(cell_size)
					rl.DrawRectangleRec(transmute(rl.Rectangle)eg_rectangle, rl.DARKPURPLE)
				}
			}

			{ // draw frogger
				frogger_cell_rectangle := [4]f32{frogger_pos.x, frogger_pos.y, 1, 1}
				frogger_rectangle := frogger_cell_rectangle * f32(cell_size)
				rl.DrawRectangleRec(transmute(rl.Rectangle)frogger_rectangle, rl.GREEN)
				rl.DrawRectangleLinesEx(transmute(rl.Rectangle)frogger_rectangle, 4, rl.DARKGREEN)
			}
	
			if debug_show_grid { // draw grid
	
				for x : i32 = 0; x < number_of_grid_cells_on_axis_x; x += 1 {
					cam_x := f32(x * cell_size)
					cam_start_y : f32 = 0
					cam_end_y := f32(game_screen_height)
					rl.DrawLineV([2]f32{cam_x, cam_start_y}, [2]f32{cam_x, cam_end_y}, rl.BLACK)
				}

				for y : i32 = 0; y < number_of_grid_cells_on_axis_y; y += 1 {
					cam_y := f32(y * cell_size)
					cam_start_x : f32 = 0
					cam_end_x := f32(game_screen_width)
					rl.DrawLineV([2]f32{cam_start_x, cam_y}, [2]f32{cam_end_x, cam_y}, rl.BLACK)
				}

			}			
		}

		{ // DRAW TO WINDOW
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.BLACK)

			src := rl.Rectangle{ 0, 0, f32(target.texture.width), f32(-target.texture.height) }
			
			window_midpoint_x    := screen_width -  (f32(game_screen_width)   * scale) / 2
			window_midpoint_y    := screen_height - (f32(game_screen_height)  * scale) / 2
			window_scaled_width  := f32(game_screen_width)  * scale
			window_scaled_height := f32(game_screen_height) * scale

			dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}
			rl.DrawTexturePro(target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)
		}

	}

}