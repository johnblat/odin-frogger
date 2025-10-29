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


raylib_to_game_keyboard_map : #sparse [rl.KeyboardKey]game.Keyboard_Key = {
	// Null
	rl.KeyboardKey.KEY_NULL = game.Keyboard_Key.UNKNOWN,

	// Alphanumeric
	rl.KeyboardKey.A = game.Keyboard_Key.A,
	rl.KeyboardKey.B = game.Keyboard_Key.B,
	rl.KeyboardKey.C = game.Keyboard_Key.C,
	rl.KeyboardKey.D = game.Keyboard_Key.D,
	rl.KeyboardKey.E = game.Keyboard_Key.E,
	rl.KeyboardKey.F = game.Keyboard_Key.F,
	rl.KeyboardKey.G = game.Keyboard_Key.G,
	rl.KeyboardKey.H = game.Keyboard_Key.H,
	rl.KeyboardKey.I = game.Keyboard_Key.I,
	rl.KeyboardKey.J = game.Keyboard_Key.J,
	rl.KeyboardKey.K = game.Keyboard_Key.K,
	rl.KeyboardKey.L = game.Keyboard_Key.L,
	rl.KeyboardKey.M = game.Keyboard_Key.M,
	rl.KeyboardKey.N = game.Keyboard_Key.N,
	rl.KeyboardKey.O = game.Keyboard_Key.O,
	rl.KeyboardKey.P = game.Keyboard_Key.P,
	rl.KeyboardKey.Q = game.Keyboard_Key.Q,
	rl.KeyboardKey.R = game.Keyboard_Key.R,
	rl.KeyboardKey.S = game.Keyboard_Key.S,
	rl.KeyboardKey.T = game.Keyboard_Key.T,
	rl.KeyboardKey.U = game.Keyboard_Key.U,
	rl.KeyboardKey.V = game.Keyboard_Key.V,
	rl.KeyboardKey.W = game.Keyboard_Key.W,
	rl.KeyboardKey.X = game.Keyboard_Key.X,
	rl.KeyboardKey.Y = game.Keyboard_Key.Y,
	rl.KeyboardKey.Z = game.Keyboard_Key.Z,

	// Numbers
	rl.KeyboardKey.ONE = game.Keyboard_Key._1,
	rl.KeyboardKey.TWO = game.Keyboard_Key._2,
	rl.KeyboardKey.THREE = game.Keyboard_Key._3,
	rl.KeyboardKey.FOUR = game.Keyboard_Key._4,
	rl.KeyboardKey.FIVE = game.Keyboard_Key._5,
	rl.KeyboardKey.SIX = game.Keyboard_Key._6,
	rl.KeyboardKey.SEVEN = game.Keyboard_Key._7,
	rl.KeyboardKey.EIGHT = game.Keyboard_Key._8,
	rl.KeyboardKey.NINE = game.Keyboard_Key._9,
	rl.KeyboardKey.ZERO = game.Keyboard_Key._0,

	// Punctuation
	rl.KeyboardKey.APOSTROPHE = game.Keyboard_Key.APOSTROPHE,
	rl.KeyboardKey.COMMA = game.Keyboard_Key.COMMA,
	rl.KeyboardKey.MINUS = game.Keyboard_Key.MINUS,
	rl.KeyboardKey.PERIOD = game.Keyboard_Key.PERIOD,
	rl.KeyboardKey.SLASH = game.Keyboard_Key.SLASH,
	rl.KeyboardKey.SEMICOLON = game.Keyboard_Key.SEMICOLON,
	rl.KeyboardKey.EQUAL = game.Keyboard_Key.EQUALS,
	rl.KeyboardKey.LEFT_BRACKET = game.Keyboard_Key.LEFTBRACKET,
	rl.KeyboardKey.BACKSLASH = game.Keyboard_Key.BACKSLASH,
	rl.KeyboardKey.RIGHT_BRACKET = game.Keyboard_Key.RIGHTBRACKET,
	rl.KeyboardKey.GRAVE = game.Keyboard_Key.GRAVE,

	// Space / editing
	rl.KeyboardKey.SPACE = game.Keyboard_Key.SPACE,
	rl.KeyboardKey.ESCAPE = game.Keyboard_Key.ESCAPE,
	rl.KeyboardKey.ENTER = game.Keyboard_Key.RETURN,
	rl.KeyboardKey.TAB = game.Keyboard_Key.TAB,
	rl.KeyboardKey.BACKSPACE = game.Keyboard_Key.BACKSPACE,
	rl.KeyboardKey.INSERT = game.Keyboard_Key.INSERT,
	rl.KeyboardKey.DELETE = game.Keyboard_Key.DELETE,

	// Navigation
	rl.KeyboardKey.RIGHT = game.Keyboard_Key.RIGHT,
	rl.KeyboardKey.LEFT = game.Keyboard_Key.LEFT,
	rl.KeyboardKey.DOWN = game.Keyboard_Key.DOWN,
	rl.KeyboardKey.UP = game.Keyboard_Key.UP,
	rl.KeyboardKey.PAGE_UP = game.Keyboard_Key.PAGEUP,
	rl.KeyboardKey.PAGE_DOWN = game.Keyboard_Key.PAGEDOWN,
	rl.KeyboardKey.HOME = game.Keyboard_Key.HOME,
	rl.KeyboardKey.END = game.Keyboard_Key.END,

	// Lock / Print
	rl.KeyboardKey.CAPS_LOCK = game.Keyboard_Key.CAPSLOCK,
	rl.KeyboardKey.SCROLL_LOCK = game.Keyboard_Key.SCROLLLOCK,
	rl.KeyboardKey.NUM_LOCK = game.Keyboard_Key.NUMLOCKCLEAR,
	rl.KeyboardKey.PRINT_SCREEN = game.Keyboard_Key.PRINTSCREEN,
	rl.KeyboardKey.PAUSE = game.Keyboard_Key.PAUSE,

	// Function keys
	rl.KeyboardKey.F1 = game.Keyboard_Key.F1,
	rl.KeyboardKey.F2 = game.Keyboard_Key.F2,
	rl.KeyboardKey.F3 = game.Keyboard_Key.F3,
	rl.KeyboardKey.F4 = game.Keyboard_Key.F4,
	rl.KeyboardKey.F5 = game.Keyboard_Key.F5,
	rl.KeyboardKey.F6 = game.Keyboard_Key.F6,
	rl.KeyboardKey.F7 = game.Keyboard_Key.F7,
	rl.KeyboardKey.F8 = game.Keyboard_Key.F8,
	rl.KeyboardKey.F9 = game.Keyboard_Key.F9,
	rl.KeyboardKey.F10 = game.Keyboard_Key.F10,
	rl.KeyboardKey.F11 = game.Keyboard_Key.F11,
	rl.KeyboardKey.F12 = game.Keyboard_Key.F12,

	// Modifiers
	rl.KeyboardKey.LEFT_SHIFT = game.Keyboard_Key.LSHIFT,
	rl.KeyboardKey.LEFT_CONTROL = game.Keyboard_Key.LCTRL,
	rl.KeyboardKey.LEFT_ALT = game.Keyboard_Key.LALT,
	rl.KeyboardKey.LEFT_SUPER = game.Keyboard_Key.LGUI,
	rl.KeyboardKey.RIGHT_SHIFT = game.Keyboard_Key.RSHIFT,
	rl.KeyboardKey.RIGHT_CONTROL = game.Keyboard_Key.RCTRL,
	rl.KeyboardKey.RIGHT_ALT = game.Keyboard_Key.RALT,
	rl.KeyboardKey.RIGHT_SUPER = game.Keyboard_Key.RGUI,
	rl.KeyboardKey.KB_MENU = game.Keyboard_Key.MENU,

	// Keypad
	rl.KeyboardKey.KP_0 = game.Keyboard_Key.KP_0,
	rl.KeyboardKey.KP_1 = game.Keyboard_Key.KP_1,
	rl.KeyboardKey.KP_2 = game.Keyboard_Key.KP_2,
	rl.KeyboardKey.KP_3 = game.Keyboard_Key.KP_3,
	rl.KeyboardKey.KP_4 = game.Keyboard_Key.KP_4,
	rl.KeyboardKey.KP_5 = game.Keyboard_Key.KP_5,
	rl.KeyboardKey.KP_6 = game.Keyboard_Key.KP_6,
	rl.KeyboardKey.KP_7 = game.Keyboard_Key.KP_7,
	rl.KeyboardKey.KP_8 = game.Keyboard_Key.KP_8,
	rl.KeyboardKey.KP_9 = game.Keyboard_Key.KP_9,
	rl.KeyboardKey.KP_DECIMAL = game.Keyboard_Key.KP_PERIOD,
	rl.KeyboardKey.KP_DIVIDE = game.Keyboard_Key.KP_DIVIDE,
	rl.KeyboardKey.KP_MULTIPLY = game.Keyboard_Key.KP_MULTIPLY,
	rl.KeyboardKey.KP_SUBTRACT = game.Keyboard_Key.KP_MINUS,
	rl.KeyboardKey.KP_ADD = game.Keyboard_Key.KP_PLUS,
	rl.KeyboardKey.KP_ENTER = game.Keyboard_Key.KP_ENTER,
	rl.KeyboardKey.KP_EQUAL = game.Keyboard_Key.KP_EQUALS,

	// Android keys
	rl.KeyboardKey.BACK = game.Keyboard_Key.UNKNOWN,      // map if you have BACK key
	rl.KeyboardKey.MENU = game.Keyboard_Key.UNKNOWN,      // map if you have MENU key
	rl.KeyboardKey.VOLUME_UP = game.Keyboard_Key.UNKNOWN, // map if you have VOLUMEUP
	rl.KeyboardKey.VOLUME_DOWN = game.Keyboard_Key.UNKNOWN, // map if you have VOLUMEDOWN
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

	game.game_init()


	for desc in game.texture_load_descriptions
	{
		img := rl.LoadImageFromMemory(".png", &desc.png_data[0],  i32(len(desc.png_data)))
		p_state.texture_map[desc.tex_id] = rl.LoadTextureFromImage(img)
		rl.SetTextureFilter(p_state.texture_map[desc.tex_id], rl.TextureFilter.POINT)
		rl.SetTextureWrap(p_state.texture_map[desc.tex_id], .CLAMP)
		game.g_state.textures[desc.tex_id].id = u32(desc.tex_id)
		game.g_state.textures[desc.tex_id].w = f32(p_state.texture_map[desc.tex_id].width)
		game.g_state.textures[desc.tex_id].h = f32(p_state.texture_map[desc.tex_id].height)
	}

	for desc in game.font_load_descriptions
	{
		p_state.font_map[u32(desc.font_id)] = rl.LoadFontFromMemory(".otf", &desc.font_data[0], i32(len(desc.font_data)), 256, nil, 0)
		for i, font in p_state.font_map
		{
			game.g_state.fonts[desc.font_id].packed_chars[i].x0 = 0
		}
	}

}


@(export)
memory_ptr :: proc() -> (platform_memory_ptr : rawptr, game_memory_ptr : rawptr)
{
	platform_memory_ptr = p_state
	game_memory_ptr = game.g_state
	return
}

@(export)
memory_size :: proc() -> int
{
	size := size_of(p_state) + size_of(game.g_state)
	return size
}


@(export)
hot_reload :: proc(platform_state : rawptr, game_state : rawptr)
{
	p_state = (^P_State)platform_state
	game.g_state = (^G_State)game_state
}


@(export)
update_and_render :: proc()
{
	clear(&game.g_state.render_cmds)
	dt := rl.GetFrameTime()
	for key in rl.KeyboardKey
	{
		if rl.IsKeyPressed(key) || rl.IsKeyDown(key)
		{
			game_key := raylib_to_game_keyboard_map[key]
			game.g_state.input_state.keyboard_state.curr[game_key] = true
		}
		else
		{
			game_key := raylib_to_game_keyboard_map[key]
			game.g_state.input_state.keyboard_state.curr[game_key] = false
		}
	}

	game.set_delta_time(dt)
	game.game_update()

	for &v, k in game.g_state.input_state.keyboard_state.prev
	{
		v = game.g_state.input_state.keyboard_state.curr[k]
	}

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
	
	screen_width := f32(rl.GetScreenWidth())
	screen_height := f32(rl.GetScreenHeight())

	scale := min(screen_width/game.game_resolution_width, screen_height/game.game_resolution_height)

	// 300 just chosen for no reason 
	window_scaled_width  : f32 = game.game_resolution_width * f32(scale)
	window_scaled_height : f32 = game.game_resolution_height * f32(scale)


	dst := rl.Rectangle{(screen_width - window_scaled_width)/2, (screen_height - window_scaled_height)/2, window_scaled_width, window_scaled_height}

	rl.DrawTexturePro(p_state.render_target.texture, src, dst, [2]f32{0,0}, 0, rl.WHITE)

	rl.EndDrawing()

	free_all(context.temp_allocator)

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