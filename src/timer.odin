package game

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


timer_is_playing :: proc(timer: Timer) -> bool
{
	is_complete := timer_is_complete(timer)
	return !is_complete
}


// Advances timer, and returns whether it is still playing
timer_advance :: proc(timer: ^Timer, dt: f32) -> bool
{
	timer.amount += dt
	timer.amount = min(timer.amount, timer.duration)
	if timer.loop && timer_is_complete(timer^)
	{
		timer_start(timer)
	}

	is_playing := timer_is_playing(timer^)
	return is_playing
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


timer_init :: proc(duration: f32, loop: bool) -> Timer
{
	t := Timer {
		amount = duration,
		duration = duration,
		loop = loop
	}

	return t
}