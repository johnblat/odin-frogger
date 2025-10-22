package platform_raylib

import "core:c"
import "core:fmt"
import "core:mem"
import "core:strings"

import rl "vendor:raylib"
import pirc "../pirc"
import game "../game"


Window_Save_Data :: struct
{
	x, y, width, height: i32
}


P_State :: struct
{
	render_target : rl.RenderTexture,
	texture_map : map[game.Texture_Id]rl.Texture,
	font_map : map[pirc.Font_Id]rl.Font,

}


p_state : ^P_State


global_filename_window_save_data := "window_save_data.frog"

bytes_aa_pixel_filter_shader        := #load("../pixel_filter.fs")



@(export)
is_build_requested :: proc() -> bool
{
	yes := rl.IsKeyPressed(.F5)
	if yes
	{
		return true
	}
	return false
}


@(export)
should_run :: proc() -> bool
{
	no := rl.WindowShouldClose()
	if no
	{
		return false
	}
	return true
}


@(export)
hot_reload :: proc(platform_state : rawptr, game_state : rawptr) 
{
	p_state = (^P_State)(platform_state)
	game.g_state = (^game.G_State)(game_state)
}


@(export)
free_memory :: proc()
{
	rl.UnloadRenderTexture(p_state.render_target)

	for texture_id, texture in p_state.texture_map
	{
		rl.UnloadTexture(texture)
	}

	free(game.g_state)
	free(p_state)
}


@(export)
init :: proc()
{
	p_state  = new(P_State)
	default_window_width : i32 = 224 * 4
	default_window_height : i32 = 256 * 4

	window_width : i32 = default_window_width
	window_height : i32 = default_window_height
	window_pos_x : i32 = 0
	window_pos_y : i32 = 50

	window_save_data := Window_Save_Data{}

	bytes_window_save_data, ok := game.read_entire_file(global_filename_window_save_data, context.temp_allocator)

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
	rl.SetTargetFPS(60)

	game_render_target := rl.LoadRenderTexture(i32(game.game_resolution_width), i32(game.game_resolution_height))
	rl.SetTextureFilter(game_render_target.texture, rl.TextureFilter.BILINEAR)
	rl.SetTextureWrap(game_render_target.texture, .CLAMP) // this stops sub-pixel artifacts on edges of game texture

	p_state.render_target = game_render_target

	for desc in game.texture_load_descriptions
	{
		img := rl.LoadImageFromMemory(".png", &desc.png_data[0],  i32(len(desc.png_data)))
		p_state.texture_map[desc.tex_id] = rl.LoadTextureFromImage(img)
		rl.SetTextureFilter(p_state.texture_map[desc.tex_id], rl.TextureFilter.POINT)
		rl.SetTextureWrap(p_state.texture_map[desc.tex_id], .CLAMP)
	}

	for desc in game.font_load_descriptions
	{
		p_state.font_map[u32(desc.font_id)] = rl.LoadFontFromMemory(".otf", &desc.font_data[0], i32(len(desc.font_data)), 256, nil, 0)
	}

	game.game_init()
}


@(export)
update_gameplay :: proc()
{
	dt := rl.GetFrameTime()
	game.set_delta_time(dt)
	game.game_update()
}


@(export)
render :: proc()
{
	camera := game.g_state.camera
	rl_camera := rl.Camera2D {
		offset = camera.offset,
		rotation = 0.0,
		target = camera.target,
		zoom = camera.zoom,
	}

	rl.BeginTextureMode(p_state.render_target)

	rl.BeginMode2D(rl_camera)

	cmds := game.g_state.render_cmds[:]

	for cmd in cmds
	{
		switch cmd in cmd
		{
			case pirc.Cmd_Clear:
			{
				color := transmute(rl.Color)cmd.color
				rl.ClearBackground(color)
			}
			case pirc.Cmd_Line:
			{
				color := transmute(rl.Color)cmd.color
				rl.DrawLineEx([2]f32{cmd.x1, cmd.y1}, [2]f32{cmd.x2, cmd.y2}, cmd.thick, color)
			}
			case pirc.Cmd_Rectangle_Fill:
			{
				rectangle := transmute(rl.Rectangle)cmd.rectangle
				color := transmute(rl.Color)cmd.color
				rl.DrawRectangleRec(rectangle, color)
			}
			case pirc.Cmd_Rectangle_Lines:
			{
				rectangle := transmute(rl.Rectangle)cmd.rectangle
				color := transmute(rl.Color)cmd.color
				rl.DrawRectangleLinesEx(rectangle, cmd.thick, color)
			}
			case pirc.Cmd_Text:
			{
				rl_font := p_state.font_map[cmd.font]
				ctext := fmt.ctprintf(cmd.text)
				color := transmute(rl.Color)cmd.color
				rl.DrawTextEx(rl_font, ctext, cmd.pos, cmd.size, 1, color)

			}
			case pirc.Cmd_Texture_Clip:
			{
				tex := p_state.texture_map[game.Texture_Id(cmd.tex_id)]
				src := transmute(rl.Rectangle)cmd.src_rect
				dst := transmute(rl.Rectangle)cmd.dst_rect
				tint := transmute(rl.Color)cmd.color
				rl.DrawTexturePro(tex, src, dst, cmd.rotation_origin, cmd.rotation, tint)
			}
		}
	}

	rl.EndMode2D()
	rl.EndTextureMode()
		
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	src := rl.Rectangle{ 0, 0, f32(p_state.render_target.texture.width), f32(-p_state.render_target.texture.height) }
	
	scale := 1.0

	// 300 just chosen for no reason 
	window_scaled_width  : f32 = 300 * f32(scale)
	window_scaled_height : f32 = 300 * f32(scale)

	screen_width := f32(rl.GetScreenWidth())
	screen_height := f32(rl.GetScreenHeight())

	dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}

	rl.DrawTexturePro(p_state.render_target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)

	rl.EndDrawing()
}

@(export)
platform_shutdown :: proc()
{
	when ODIN_OS != .JS { // no need to save this in web

		window_pos    := rl.GetWindowPosition()
		screen_width  := rl.GetScreenWidth()
		screen_height := rl.GetScreenHeight()

		window_save_data := Window_Save_Data {i32(window_pos.x), i32(window_pos.y), screen_width, screen_height}
		bytes_window_save_data := mem.ptr_to_bytes(&window_save_data)

		ok := game.write_entire_file(global_filename_window_save_data, bytes_window_save_data)
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


parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h))
}