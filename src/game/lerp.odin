package game


Lerp_Position :: struct
{
	timer :Timer,
	start_pos: [2]f32,
	end_pos: [2]f32,
}

Lerp_Value :: struct
{
	timer: Timer,
	start_val: f32,
	end_val: f32,
}


lerp_position_start :: proc(lerp: ^Lerp_Position, start_pos, end_pos: [2]f32)
{
	timer_start(&lerp.timer)
	lerp.start_pos = start_pos
	lerp.end_pos = end_pos
}

lerp_position_advance :: proc(lerp: ^Lerp_Position, dt: f32) -> (progress_pos: [2]f32)
{
	timer_advance(&lerp.timer, dt)
	progress_pos = lerp_position_progress_pos(lerp^)
	return
}

lerp_position_progress_pos :: proc(lerp: Lerp_Position) -> (progress_pos: [2]f32)
{
	t := timer_percentage(lerp.timer)
	t = min(t, 1.0)
	progress_pos.x = (1.0 - t) * lerp.start_pos.x + t * lerp.end_pos.x
	progress_pos.y = (1.0 - t) * lerp.start_pos.y + t * lerp.end_pos.y
	return
}

lerp_value_start :: proc(lerp: ^Lerp_Value, start_val, end_val: f32)
{
	timer_start(&lerp.timer)
	lerp.start_val = start_val
	lerp.end_val = end_val
}

lerp_value_advance :: proc(lerp: ^Lerp_Value, dt: f32) -> (progress_val: f32, just_completed: bool)
{
	just_completed = timer_advance(&lerp.timer, dt)
	progress_val = lerp_value_progress(lerp^)
	return
}

lerp_value_progress :: proc(lerp: Lerp_Value) -> (progress_val: f32)
{
	t := timer_percentage(lerp.timer)
	t = min(t, 1.0)
	progress_val = (1.0 - t) * lerp.start_val + t * lerp.end_val
	return
}