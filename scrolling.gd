extends Node2D

@onready var finger = $Finger
@onready var reels = [$reel1, $reel2, $reel3, $reel4, $reel5, $reel6, $reel7]

var current_index: int = 0
var finger_original_position: Vector2
var is_animating = false
var swipe_distance = 100
var animation_duration = 0.3

func _ready():
	finger_original_position = finger.position
	show_reel(0)

func show_reel(index: int):
	for i in range(reels.size()):
		reels[i].visible = (i == index)
		if reels[i].visible:
			reels[i].play()
		else:
			reels[i].stop()
	current_index = index

func _input(event):
	if event is InputEventMouseButton and event.pressed and not is_animating:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			animate_finger_swipe_down()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			animate_finger_swipe_up()

func animate_finger_swipe_down():
	if is_animating or current_index >= reels.size() - 1:
		return
	is_animating = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	var target_position = finger_original_position + Vector2(0, -swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)
	tween.tween_callback(func():
		is_animating = false
		show_reel(current_index + 1)
	)

func animate_finger_swipe_up():
	if is_animating or current_index <= 0:
		return
	is_animating = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	var target_position = finger_original_position + Vector2(0, swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)
	tween.tween_callback(func():
		is_animating = false
		show_reel(current_index - 1)
	)
