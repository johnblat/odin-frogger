package game

import "core:math"
import rl "vendor:raylib"

// Animation :: struct 
// {
// 	timer       :Timer,
// 	frame_clips :[]rl.Rectangle, 
// }

animation_get_current_frame :: proc(t, fps: f32, number_of_frames: int) -> int
{
	ret := int(math.mod(t * fps, f32(number_of_frames)))
	return ret
}


animation_get_duration :: proc(fps: f32, number_of_frames: int) -> f32
{
	ret := f32(number_of_frames) / fps
	return ret
}


animation_get_frame_sprite_clip :: proc(t, fps: f32, frame_clips: []rl.Rectangle) -> rl.Rectangle
{
	frame_index := animation_get_current_frame(t, fps, len(frame_clips))
	frame_clip_rectangle := frame_clips[frame_index]
	return frame_clip_rectangle
}

