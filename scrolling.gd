extends Node2D

@onready var finger = $Finger

var finger_original_position: Vector2
var is_animating = false
var swipe_distance = 100
var animation_duration = 0.3

func _ready():
	finger_original_position = finger.position

func _input(event):
	if event is InputEventMouseButton and event.pressed and not is_animating:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			animate_finger_swipe_down()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			animate_finger_swipe_up()

func animate_finger_swipe_down():
	if is_animating:
		return
	
	is_animating = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	var target_position = finger_original_position + Vector2(0, -swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)
	tween.tween_callback(func(): is_animating = false)

func animate_finger_swipe_up():
	if is_animating:
		return
	
	is_animating = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	var target_position = finger_original_position + Vector2(0, swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)
	tween.tween_callback(func(): is_animating = false)
