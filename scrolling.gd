extends Node2D

@onready var finger = $Finger
var finger_original_position: Vector2
var is_animating = false
var swipe_distance = 100  # How far the finger moves up
var animation_duration = 0.3  # Animation duration in seconds

func _ready():
	# Store the original position of the finger
	finger_original_position = finger.position

func _input(event):
	# Check for mouse wheel scroll events
	if event is InputEventMouseButton:
		if event.pressed and not is_animating:
			# Scroll down (button index 5) makes finger swipe up
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				animate_finger_swipe()
			# Optional: Scroll up (button index 4) could do reverse animation
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				animate_finger_swipe_reverse()

func animate_finger_swipe():
	if is_animating:
		return
	
	is_animating = true
	
	# Create a tween for smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	# Move finger up
	var target_position = finger_original_position + Vector2(0, -swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	
	# Move finger back to original position
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)
	
	# Reset animation flag when done
	tween.tween_callback(func(): is_animating = false)

func animate_finger_swipe_reverse():
	if is_animating:
		return
	
	is_animating = true
	
	# Create a tween for smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	# Move finger down first
	var target_position = finger_original_position + Vector2(0, swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	
	# Move finger back to original position
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)
	
	# Reset animation flag when done
	tween.tween_callback(func(): is_animating = false)

# Alternative approach using delta-based movement (more responsive)
func _process(delta):
	# You can also detect scroll input here if preferred
	pass
