package main

import rl "vendor:raylib"
import game ".."
// https://forum.sublimetext.com/t/my-sublime-text-windows-cheat-sheet/8411


draw_rectangle_on_grid :: proc(rectangle: rl.Rectangle, color: rl.Color, cell_size: f32)
{
	render_rectangle := rl.Rectangle {
		rectangle.x      * cell_size,
		rectangle.y      * cell_size,
		rectangle.width  * cell_size,
		rectangle.height * cell_size,
	}
	rl.DrawRectangleRec(render_rectangle, color)
}


main :: proc () {

	game.game_init_platform()
	game.game_init()

	


	for game.game_should_run() 
	{
		game.game_update()

	}

}