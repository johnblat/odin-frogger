package main

import platform_raylib "../../platform_raylib"


main :: proc () {
	
	platform_raylib.init()

	for platform_raylib.should_run()
	{
		platform_raylib.update_gameplay()
		platform_raylib.render()
	}

	platform_raylib.platform_shutdown()
	// game.game_shutdown()
}