package main

import rl "vendor:raylib"
import game ".."


main :: proc () {
	
	game.game_init_platform()
	game.game_init()

	for game.game_should_run() 
	{
		game.game_update()
	}

}