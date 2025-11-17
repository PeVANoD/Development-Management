extends Node2D

func _ready():
	set_process(false)

func _process(_delta):
	eyes_follow()

func eyes_follow():
	var eye1_center = $"1".global_position
	var eye2_center = $"2".global_position
	var mouse_pos = get_global_mouse_position()
	var max_offset = 3
	var offset1 = (mouse_pos - eye1_center).limit_length(max_offset)
	var offset2 = (mouse_pos - eye2_center).limit_length(max_offset)
	$"1/pupil".position = lerp($"1/pupil".position,Vector2(offset1.x, -offset1.y),0.2)
	$"2/pupil".position = lerp($"2/pupil".position,-offset2,0.2)
