extends Node2D

@onready var finger = $Finger
@onready var phone = $Iphone
@onready var feed_container = $FeedContainer

var finger_original_position: Vector2
var is_animating = false
var swipe_distance = 100
var animation_duration = 0.3

# Video feed variables
var video_reels = []
var current_reel_index = 0
var reel_height = 400
var phone_screen_size = Vector2(180, 320)  # Adjust to match your phone's screen area

# Your video file paths - put your video files in res://videos/
var video_paths = [
	"res://videos/reel1.ogv",
	"res://videos/reel2.ogv", 
	"res://videos/reel3.ogv",
	"res://videos/reel4.ogv",
	"res://videos/reel5.ogv"
]

# Reel metadata (optional - you can add usernames, descriptions, etc.)
var reel_metadata = [
	{"username": "@user1", "description": "Cool video!", "likes": "1.2K"},
	{"username": "@user2", "description": "Amazing content", "likes": "856"},
	{"username": "@user3", "description": "Check this out!", "likes": "2.1K"},
	{"username": "@user4", "description": "Viral moment", "likes": "5.3K"},
	{"username": "@user5", "description": "Don't miss this", "likes": "987"}
]

func _ready():
	finger_original_position = finger.position
	setup_feed_container()
	load_video_reels()
	# Start playing first video after a short delay
	await get_tree().process_frame
	play_current_video()

func setup_feed_container():
	if not feed_container:
		feed_container = Node2D.new()
		feed_container.name = "FeedContainer"
		add_child(feed_container)
	
	# Position container to match phone screen area
	feed_container.position = Vector2(phone.position.x, phone.position.y - 150)

func load_video_reels():
	# Clear existing reels
	for child in feed_container.get_children():
		if child.name.begins_with("Reel_"):
			child.queue_free()
	
	video_reels.clear()
	
	# Create video reel nodes
	for i in range(video_paths.size()):
		var reel = create_video_reel(video_paths[i], reel_metadata[i], i)
		feed_container.add_child(reel)
		video_reels.append(reel)
		
		# Position reels vertically
		reel.position.y = i * reel_height

func create_video_reel(video_path: String, metadata: Dictionary, index: int) -> Node2D:
	var reel = Node2D.new()
	reel.name = "Reel_" + str(index)
	
	# Create VideoStreamPlayer (Godot 4.4 compatible)
	var video_player = VideoStreamPlayer.new()
	video_player.name = "VideoPlayer"
	
	# Load video file - Updated for Godot 4.4
	if FileAccess.file_exists(video_path):
		var video_stream = load(video_path) as VideoStream
		if video_stream:
			video_player.stream = video_stream
		else:
			print("Failed to load video: ", video_path)
			return create_placeholder_reel(metadata, index)
	else:
		print("Video file not found: ", video_path)
		return create_placeholder_reel(metadata, index)
	
	# Configure video player - Updated for Godot 4.4
	video_player.autoplay = false
	video_player.loop = true
	video_player.volume_db = -10  # Lower volume for multiple videos
	
	# Scale and position video to fit phone screen
	video_player.position = Vector2(-phone_screen_size.x/2, -phone_screen_size.y/2)
	video_player.size = phone_screen_size
	
	reel.add_child(video_player)
	
	# Add a CanvasLayer for UI overlay to ensure it's on top
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	reel.add_child(ui_layer)
	
	# Add overlay UI elements
	add_reel_overlay_ui(ui_layer, metadata)
	
	return reel

func create_placeholder_reel(metadata: Dictionary, index: int) -> Node2D:
	# Fallback if video doesn't exist
	var reel = Node2D.new()
	reel.name = "Reel_" + str(index)
	
	var bg = ColorRect.new()
	bg.size = phone_screen_size
	bg.position = Vector2(-phone_screen_size.x/2, -phone_screen_size.y/2)
	bg.color = Color.BLACK
	reel.add_child(bg)
	
	var error_label = Label.new()
	error_label.text = "Video not found"
	error_label.position = Vector2(-50, 0)
	error_label.add_theme_color_override("font_color", Color.WHITE)
	reel.add_child(error_label)
	
	# Add UI layer for placeholder too
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	reel.add_child(ui_layer)
	
	add_reel_overlay_ui(ui_layer, metadata)
	return reel

func add_reel_overlay_ui(ui_parent: CanvasLayer, metadata: Dictionary):
	# Create a Control node for UI positioning
	var ui_control = Control.new()
	ui_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_parent.add_child(ui_control)
	
	# Right side UI (like IG reels) - positioned relative to phone screen
	var ui_x = phone.position.x + 70
	var base_y = phone.position.y - 100
	
	# Profile picture placeholder
	var profile_pic = ColorRect.new()
	profile_pic.size = Vector2(40, 40)
	profile_pic.position = Vector2(ui_x, base_y - 40)
	profile_pic.color = Color.WHITE
	ui_control.add_child(profile_pic)
	
	# Like button with heart shape (using ColorRect for simplicity)
	var like_btn = ColorRect.new()
	like_btn.size = Vector2(30, 30)
	like_btn.position = Vector2(ui_x + 5, base_y + 10)
	like_btn.color = Color.RED
	ui_control.add_child(like_btn)
	
	var like_count = Label.new()
	like_count.text = metadata.get("likes", "0")
	like_count.position = Vector2(ui_x, base_y + 45)
	like_count.add_theme_font_size_override("font_size", 10)
	like_count.add_theme_color_override("font_color", Color.WHITE)
	ui_control.add_child(like_count)
	
	# Comment button
	var comment_btn = ColorRect.new()
	comment_btn.size = Vector2(30, 30)
	comment_btn.position = Vector2(ui_x + 5, base_y + 70)
	comment_btn.color = Color.WHITE
	ui_control.add_child(comment_btn)
	
	# Share button
	var share_btn = ColorRect.new()
	share_btn.size = Vector2(30, 30)
	share_btn.position = Vector2(ui_x + 5, base_y + 105)
	share_btn.color = Color.WHITE
	ui_control.add_child(share_btn)
	
	# Bottom text overlay
	var username = Label.new()
	username.text = metadata.get("username", "@user")
	username.position = Vector2(phone.position.x - 80, phone.position.y + 100)
	username.add_theme_font_size_override("font_size", 14)
	username.add_theme_color_override("font_color", Color.WHITE)
	# Add shadow for better readability
	username.add_theme_color_override("font_shadow_color", Color.BLACK)
	username.add_theme_constant_override("shadow_offset_x", 1)
	username.add_theme_constant_override("shadow_offset_y", 1)
	ui_control.add_child(username)
	
	var description = Label.new()
	description.text = metadata.get("description", "")
	description.position = Vector2(phone.position.x - 80, phone.position.y + 120)
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", Color.WHITE)
	description.add_theme_color_override("font_shadow_color", Color.BLACK)
	description.add_theme_constant_override("shadow_offset_x", 1)
	description.add_theme_constant_override("shadow_offset_y", 1)
	ui_control.add_child(description)

func _input(event):
	if event is InputEventMouseButton and event.pressed and not is_animating:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_to_next_reel()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_to_previous_reel()

func scroll_to_next_reel():
	if current_reel_index >= video_reels.size() - 1:
		return
	
	# Pause current video
	pause_current_video()
	
	current_reel_index += 1
	animate_feed_scroll()
	animate_finger_swipe()
	
	# Play new video after animation
	await get_tree().create_timer(animation_duration).timeout
	play_current_video()

func scroll_to_previous_reel():
	if current_reel_index <= 0:
		return
	
	pause_current_video()
	
	current_reel_index -= 1
	animate_feed_scroll()
	animate_finger_swipe_reverse()
	
	await get_tree().create_timer(animation_duration).timeout
	play_current_video()

func animate_feed_scroll():
	if is_animating:
		return
	
	is_animating = true
	
	var target_y = phone.position.y - 150 - (current_reel_index * reel_height)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	tween.tween_property(feed_container, "position:y", target_y, animation_duration)
	tween.tween_callback(func(): is_animating = false)

func animate_finger_swipe():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	var target_position = finger_original_position + Vector2(0, -swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)

func animate_finger_swipe_reverse():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	var target_position = finger_original_position + Vector2(0, swipe_distance)
	tween.tween_property(finger, "position", target_position, animation_duration * 0.6)
	tween.tween_property(finger, "position", finger_original_position, animation_duration * 0.4)

func play_current_video():
	if current_reel_index < video_reels.size():
		var current_reel = video_reels[current_reel_index]
		var video_player = current_reel.get_node_or_null("VideoPlayer")
		if video_player and video_player is VideoStreamPlayer:
			video_player.play()

func pause_current_video():
	if current_reel_index < video_reels.size():
		var current_reel = video_reels[current_reel_index]
		var video_player = current_reel.get_node_or_null("VideoPlayer")
		if video_player and video_player is VideoStreamPlayer:
			video_player.stop()

# Optional: Add methods for better video management
func pause_all_videos():
	for reel in video_reels:
		var video_player = reel.get_node_or_null("VideoPlayer")
		if video_player and video_player is VideoStreamPlayer:
			video_player.stop()

func get_current_video_player() -> VideoStreamPlayer:
	if current_reel_index < video_reels.size():
		var current_reel = video_reels[current_reel_index]
		return current_reel.get_node_or_null("VideoPlayer") as VideoStreamPlayer
	return null
