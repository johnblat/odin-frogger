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


timer_advance :: proc(timer: ^Timer, dt: f32)
{
	timer.amount += dt
	timer.amount = min(timer.amount, timer.duration)
	if timer.loop && timer_is_complete(timer^)
	{
		timer_start(timer)
	}
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
