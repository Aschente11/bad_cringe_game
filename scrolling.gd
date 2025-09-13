extends Node2D

@onready var finger = $Finger
@onready var reels = [$reel1, $reel2, $reel3, $reel4, $reel5, $reel6, $reel7, $reel9, $reel10]

# QTE UI elements
@onready var qte_ui = $QTE_UI
@onready var qte_circle = $QTE_UI/QTECircle
@onready var keys_label = $QTE_UI/QTECircle/CenterContent/KeysLabel
@onready var count_label = $QTE_UI/QTECircle/CenterContent/CountLabel
@onready var countdown_label = $QTE_UI/QTECircle/CenterContent/CountdownLabel

# New progress donut elements
@onready var progress_donut = $QTE_UI/QTECircle/ProgressDonut
@onready var countdown_donut = $QTE_UI/QTECircle/CountdownDonut

# Cringe UI elements (unchanged)
@onready var cringe_ui = $CringeUI
@onready var cringe_fill = $CringeUI/CringeBar/CringeFill
@onready var cringe_value = $CringeUI/CringeBar/CringeValue
@onready var cringe_icon = $CringeUI/CringeBar/CringeIcon

var watched_reels = {}  # Dictionary to track which reels have been fully watched
var current_reel_watched = false  # Has current reel been watched completely
var reel_watch_timer = 0.0
var reel_duration = 5.0  # Adjust this to match your reel duration
var failed_qte_on_current_reel = false  # Track if QTE was failed on current reel

var current_index: int = 0
var finger_original_position: Vector2
var is_animating = false
var swipe_distance = 100
var animation_duration = 0.3
var reel_sequence = []
var sequence_index = 0 

# QTE System variables
var qte_active = false
var qte_timer = 0.0
var qte_duration = 3.0
var qte_required_presses = 10
var qte_current_presses = 0
var qte_key_combo = []
var current_combo_keys = []
var cringe_level = 0
var max_cringe = 100
var game_over_triggered = false

# UI Animation tweens
var pulse_tween: Tween
var countdown_tween: Tween
var progress_tween: Tween
var cringe_tween: Tween

# Available key combinations for QTE
var key_combinations = [
	[KEY_E, KEY_R],
	[KEY_Q, KEY_W],
	[KEY_A, KEY_S],
	[KEY_Z, KEY_X],
	[KEY_C, KEY_V]
]


func _ready():
	finger_original_position = finger.position
	create_randomized_sequence()  # Create the random sequence
	show_reel_by_sequence(0)  # Show first reel in sequence
	setup_qte_ui()
	setup_cringe_ui()

func create_randomized_sequence():
	reel_sequence.clear()
	# Fill array with reel indices
	for i in range(reels.size()):
		reel_sequence.append(i)
	
	# Shuffle the array
	reel_sequence.shuffle()
	sequence_index = 0
	print("New reel sequence: ", reel_sequence)
	
func show_reel_by_sequence(seq_index: int):
	if seq_index < 0 or seq_index >= reel_sequence.size():
		return
	
	sequence_index = seq_index
	var reel_index = reel_sequence[sequence_index]
	
	# Hide all reels
	for i in range(reels.size()):
		reels[i].visible = false
		reels[i].stop()
	
	# Show the current reel
	reels[reel_index].visible = true
	reels[reel_index].play()
	current_index = reel_index
	
	# Reset watching status for new reel
	current_reel_watched = watched_reels.get(reel_index, false)
	failed_qte_on_current_reel = false
	reel_watch_timer = 0.0
	
	if qte_ui:
		await get_tree().create_timer(0.5).timeout
		start_qte()


func setup_qte_ui():
	if qte_ui:
		qte_ui.visible = false
	
	# Setup countdown label
	if countdown_label:
		countdown_label.text = ""
		countdown_label.add_theme_font_size_override("font_size", 14)
		countdown_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))

func setup_cringe_ui():
	update_cringe_display()

func show_reel(index: int):
	for i in range(reels.size()):
		reels[i].visible = (i == index)
		if reels[i].visible:
			reels[i].play()
			if qte_ui:
				await get_tree().create_timer(0.5).timeout
				start_qte()
		else:
			reels[i].stop()
	current_index = index

func start_qte():
	if qte_active or not qte_ui:
		return
		
	qte_active = true
	qte_timer = qte_duration
	qte_current_presses = 0
	
	# Select random key combination
	qte_key_combo = key_combinations[randi() % key_combinations.size()]
	current_combo_keys = []
	
	# Show QTE UI with dramatic entrance
	qte_ui.visible = true
	animate_qte_entrance()
	update_qte_display()
	update_progress_donut()
	update_countdown_donut()
	start_ui_animations()
	
	print("QTE Started! Press " + get_key_combo_string() + " rapidly!")

func animate_qte_entrance():
	if not qte_circle:
		return
		
	# Start with circle scaled down and fade in
	qte_circle.scale = Vector2.ZERO
	qte_circle.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up with bouncy effect
	tween.tween_property(qte_circle, "scale", Vector2.ONE, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(qte_circle, "modulate:a", 1.0, 0.5)

func start_ui_animations():
	# Gentle pulsing animation for the whole circle
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(qte_circle, "scale", Vector2(1.05, 1.05), 0.8)
	pulse_tween.tween_property(qte_circle, "scale", Vector2.ONE, 0.8)

func get_key_combo_string() -> String:
	var combo_str = ""
	for i in range(qte_key_combo.size()):
		var key_str = OS.get_keycode_string(qte_key_combo[i])
		combo_str += key_str
		if i < qte_key_combo.size() - 1:
			combo_str += "+"
	return combo_str

func update_qte_display():
	if not qte_active:
		return
		
	if keys_label:
		keys_label.text = get_key_combo_string()
	
	if count_label:
		count_label.text = str(qte_current_presses) + "/" + str(qte_required_presses)

func update_progress_donut():
	if not progress_donut:
		return
	
	var progress = float(qte_current_presses) / float(qte_required_presses)
	
	# Update material progress (you'll need to set this in the scene)
	progress_donut.material.set_shader_parameter("progress", progress)
	
	# Change color based on progress
	var color: Color
	if progress > 0.8:
		color = Color(0.2, 1, 0.6, 0.9)  # Bright green
	elif progress > 0.5:
		color = Color(1, 0.9, 0.2, 0.9)  # Gold
	elif progress > 0.2:
		color = Color(1, 0.6, 0.2, 0.9)  # Orange
	else:
		color = Color(0.6, 0.6, 1, 0.7)  # Soft blue
	
	progress_donut.material.set_shader_parameter("donut_color", color)
	
	# Animate progress change
	if progress_tween:
		progress_tween.kill()
	progress_tween = create_tween()
	progress_tween.tween_method(
		func(val): progress_donut.material.set_shader_parameter("progress", val),
		progress_donut.material.get_shader_parameter("progress"),
		progress,
		0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func update_countdown_donut():
	if not countdown_donut:
		return
	
	var time_progress = qte_timer / qte_duration
	
	# Update countdown display
	if countdown_label:
		countdown_label.text = "%.1fs" % qte_timer
	
	# Update shader progress
	countdown_donut.material.set_shader_parameter("progress", time_progress)
	
	# Color changes based on remaining time
	var color: Color
	if time_progress > 0.6:
		color = Color(0.4, 1, 0.8, 0.6)  # Green
	elif time_progress > 0.3:
		color = Color(1, 1, 0.4, 0.7)    # Yellow
	else:
		color = Color(1, 0.4, 0.4, 0.8)  # Red - urgent!
	
	countdown_donut.material.set_shader_parameter("donut_color", color)

func _process(delta):
	if qte_active:
		qte_timer -= delta
		update_countdown_donut()
		
		if qte_timer <= 0:
			fail_qte()
	
	# Track reel watching time if QTE was failed and reel hasn't been watched
	if failed_qte_on_current_reel and not current_reel_watched:
		reel_watch_timer += delta
		
		# Mark as watched when timer reaches duration
		if reel_watch_timer >= reel_duration:
			current_reel_watched = true
			watched_reels[current_index] = true
			print("Reel " + str(current_index) + " has been fully watched! Now skippable.")
			
func _input(event):
	if qte_active and event is InputEventKey and event.pressed:
		handle_qte_input(event.keycode)
	elif event is InputEventMouseButton and event.pressed and not is_animating and not qte_active:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			animate_finger_swipe_down()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			animate_finger_swipe_up()

func handle_qte_input(keycode: int):
	if keycode in qte_key_combo:
		if keycode not in current_combo_keys:
			current_combo_keys.append(keycode)
		
		if current_combo_keys.size() == qte_key_combo.size():
			var valid_combo = true
			for required_key in qte_key_combo:
				if required_key not in current_combo_keys:
					valid_combo = false
					break
			
			if valid_combo:
				qte_current_presses += 1
				current_combo_keys.clear()
				
				animate_qte_success_flash()
				update_qte_display()
				update_progress_donut()
				
				if qte_current_presses >= qte_required_presses:
					complete_qte()
	else:
		qte_timer -= 0.1
		animate_qte_fail_flash()

func animate_qte_success_flash():
	# Success pulse effect
	if qte_circle:
		var flash_tween = create_tween()
		flash_tween.set_parallel(true)
		flash_tween.tween_property(qte_circle, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		flash_tween.tween_property(qte_circle, "scale", Vector2(1.1, 1.1), 0.1)
		flash_tween.tween_callback(func(): 
			var return_tween = create_tween()
			return_tween.set_parallel(true)
			return_tween.tween_property(qte_circle, "modulate", Color.WHITE, 0.2)
			return_tween.tween_property(qte_circle, "scale", Vector2.ONE, 0.2)
		)
	
	create_screen_flash(Color(0.3, 1, 0.6, 0.2))

func animate_qte_fail_flash():
	if qte_circle:
		var flash_tween = create_tween()
		flash_tween.tween_property(qte_circle, "modulate", Color(1.5, 0.7, 0.7, 1), 0.1)
		flash_tween.tween_property(qte_circle, "modulate", Color.WHITE, 0.2)
	
	create_screen_flash(Color(1, 0.4, 0.4, 0.2))

func create_screen_flash(flash_color: Color):
	var flash = ColorRect.new()
	get_parent().add_child(flash)
	flash.color = flash_color
	flash.size = get_viewport().get_visible_rect().size
	flash.z_index = 100
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0, 0.2)
	flash_tween.tween_callback(flash.queue_free)

func complete_qte():
	qte_active = false
	
	# Stop all QTE tweens
	if pulse_tween:
		pulse_tween.kill()
	if countdown_tween:
		countdown_tween.kill()
	if progress_tween:
		progress_tween.kill()
	
	# Dramatic success exit
	if qte_circle:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(qte_circle, "scale", Vector2(1.3, 1.3), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(qte_circle, "modulate", Color(1.5, 1.5, 1.5, 0), 0.4)
		tween.tween_callback(func(): qte_ui.visible = false)
	
	print("QTE Success! Skipping reel...")
	animate_finger_swipe_down()
	
	# Reduce cringe as reward
	cringe_level = max(0, cringe_level - 5)
	update_cringe_display()
func fail_qte():
	qte_active = false
	failed_qte_on_current_reel = true  # Mark that QTE was failed
	
	# Stop tweens
	if pulse_tween:
		pulse_tween.kill()
	if countdown_tween:
		countdown_tween.kill()
	if progress_tween:
		progress_tween.kill()
	
	# Failure shrink effect
	if qte_circle:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(qte_circle, "scale", Vector2(0.3, 0.3), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
		tween.tween_property(qte_circle, "modulate", Color(1, 0.6, 0.6, 0), 0.3)
		tween.tween_callback(func(): qte_ui.visible = false)
	
	print("QTE Failed! Must watch the reel... Reel is now unskippable until watched!")
	
	# Increase cringe significantly
	cringe_level = min(max_cringe, cringe_level + 25)
	update_cringe_display()
	animate_cringe_effect()

# Keep all existing cringe and animation functions unchanged...
func update_cringe_display():
	if cringe_fill:
		var fill_percentage = float(cringe_level) / float(max_cringe)
		var bar_height = 292
		var fill_height = bar_height * fill_percentage
		
		cringe_fill.offset_top = -4 - fill_height
		
		var color: Color
		if cringe_level > 75:
			color = Color(1, 0.2, 0.2, 0.9)
			cringe_icon.text = "💀"
		elif cringe_level > 50:
			color = Color(1, 0.6, 0, 0.9)
			cringe_icon.text = "😵"
		elif cringe_level > 25:
			color = Color(1, 1, 0, 0.9)
			cringe_icon.text = "😬"
		else:
			color = Color(0, 1, 0.5, 0.9)
			cringe_icon.text = "😊"
		
		if cringe_tween:
			cringe_tween.kill()
		cringe_tween = create_tween()
		cringe_tween.tween_property(cringe_fill, "color", color, 0.3)
	
	if cringe_value:
		cringe_value.text = str(cringe_level)
		
	if cringe_level >= max_cringe and not game_over_triggered:
		trigger_game_over()

func animate_cringe_effect():
	var original_pos = position
	var shake_tween = create_tween()
	shake_tween.set_loops(6)
	shake_tween.tween_property(self, "position", original_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.05)
	shake_tween.tween_callback(func(): position = original_pos)
	
	if cringe_fill:
		var pulse_tween = create_tween()
		pulse_tween.set_loops(3)
		pulse_tween.tween_property(cringe_fill, "scale", Vector2(1.2, 1.05), 0.1)
		pulse_tween.tween_property(cringe_fill, "scale", Vector2.ONE, 0.1)

func animate_finger_swipe_down():
	# Check if reel is unskippable
	if failed_qte_on_current_reel and not current_reel_watched:
		print("Cannot skip! You must watch this reel completely after failing QTE.")
		animate_skip_denied()
		return
	
	if is_animating or sequence_index >= reel_sequence.size() - 1:
		if sequence_index >= reel_sequence.size() - 1:
			create_randomized_sequence()
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
		show_reel_by_sequence(sequence_index + 1)
	)

# Modify your animate_finger_swipe_up function:
func animate_finger_swipe_up():
	# Don't allow going back if current reel is unskippable
	if failed_qte_on_current_reel and not current_reel_watched:
		print("Cannot skip! You must watch this reel completely after failing QTE.")
		animate_skip_denied()
		return
	
	if is_animating or sequence_index <= 0:
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
		show_reel_by_sequence(sequence_index - 1)
	)
func trigger_game_over():
	game_over_triggered = true
	qte_active = false  # Stop any active QTE
	
	# Optional: Add a brief delay and screen effect before transitioning
	var tween = create_tween()
	tween.tween_callback(func(): 
		# Screen flash effect
		create_screen_flash(Color(1, 0, 0, 0.5))
	)
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://game_over.tscn")
	)

func animate_skip_denied():
	if is_animating:
		return
	
	is_animating = true
	
	# Shake the finger to indicate denial
	var original_pos = finger.position
	var shake_tween = create_tween()
	shake_tween.set_loops(4)
	shake_tween.tween_property(finger, "position", original_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 0.08)
	shake_tween.tween_callback(func(): 
		finger.position = original_pos
		is_animating = false
	)
	
	# Visual feedback - red flash
	create_screen_flash(Color(1, 0.3, 0.3, 0.3))
	
	# Optional: Show a temporary message
	show_unskippable_message()

# Add this function to show a message when skip is denied:
func show_unskippable_message():
	# Create a temporary label to show the message
	var message_label = Label.new()
	get_parent().add_child(message_label)
	
	message_label.text = "Watch the full reel!"
	message_label.add_theme_font_size_override("font_size", 24)
	message_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	
	# Position it in the center of the screen
	var viewport_size = get_viewport().get_visible_rect().size
	message_label.position = Vector2(viewport_size.x / 2 - 100, viewport_size.y / 2)
	message_label.z_index = 100
	
	# Animate the message
	message_label.modulate.a = 0
	var msg_tween = create_tween()
	msg_tween.set_parallel(true)
	msg_tween.tween_property(message_label, "modulate:a", 1.0, 0.3)
	msg_tween.tween_property(message_label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Fade out and remove
	await get_tree().create_timer(1.5).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(message_label.queue_free)
