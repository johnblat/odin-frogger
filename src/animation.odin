package game

import "core:math"
import rl "vendor:raylib"


get_anim_current_frame_index :: proc(t, fps: f32, number_of_frames: int) -> int
{
	ret := int(math.mod(t * fps, f32(number_of_frames)))
	return ret
}


get_anim_duration :: proc(fps: f32, number_of_frames: int) -> f32
{
	ret := f32(number_of_frames) / fps
	return ret
}


get_anim_current_frame_sprite_sheet_clip :: proc(t, fps: f32, frame_clips: []rl.Rectangle) -> rl.Rectangle
{
	frame_index := get_anim_current_frame_index(t, fps, len(frame_clips))
	frame_clip_rectangle := frame_clips[frame_index]
	return frame_clip_rectangle
}

