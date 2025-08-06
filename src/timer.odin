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


Animation_Timer :: struct {
	t: f32,
	loop: bool,
	playing: bool,
}

animation_timer_is_complete :: proc(animation_timer: Animation_Timer, number_of_frames: int, fps: f32) -> bool
{
	duration := animation_get_duration(fps, number_of_frames)
	is_complete := (animation_timer.t >= duration && !animation_timer.loop ) || !animation_timer.playing
	return is_complete
}

animation_timer_is_playing :: proc(animation_timer: Animation_Timer) -> bool
{
	return animation_timer.playing
}

animation_timer_advance :: proc(animation_timer: ^Animation_Timer, number_of_frames: int, fps: f32, dt: f32) -> bool
{
	if !animation_timer.playing
	{
		return false
	}
	duration := animation_get_duration(fps, number_of_frames)
	animation_timer.t += dt
	if animation_timer.t > duration && !animation_timer.loop
	{
		animation_timer.playing = false
	}
	return animation_timer.playing
}

animation_timer_start :: proc(animation_timer: ^Animation_Timer)
{
	animation_timer.t = 0
	animation_timer.playing = true
}
