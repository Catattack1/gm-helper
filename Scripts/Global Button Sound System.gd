# GlobalButtonSounds.gd
# Autoload script that automatically adds sound effects to ALL buttons in the game
# Add this to Project Settings -> Autoload as "GlobalButtonSounds"

extends Node

# Audio file paths - edit these to point to your sound files
const HOVER_SOUND_PATH_1 = "res://Assets/Audio/SFX/Modern2.mp3"
const HOVER_SOUND_PATH_2 = "res://Assets/Audio/SFX/Modern3.mp3"
const HOVER_SOUND_PATH_3 = "res://Assets/Audio/SFX/Modern4.mp3"
const CLICK_SOUND_PATH = "res://Assets/Audio/SFX/Modern1.mp3"
const TOGGLE_ON_SOUND_PATH = "res://Assets/Audio/SFX/Modern15.mp3"
const TOGGLE_OFF_SOUND_PATH = "res://Assets/Audio/SFX/Modern14.mp3"

# Loaded audio streams
var hover_sounds: Array[AudioStream] = []
var click_sound: AudioStream
var toggle_on_sound: AudioStream
var toggle_off_sound: AudioStream

# Audio players for each sound type
var hover_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var toggle_player: AudioStreamPlayer

# Track which buttons we've already connected to avoid duplicates
var connected_buttons: Dictionary = {}

func _ready() -> void:
	# Load hover audio files (multiple variations)
	if FileAccess.file_exists(HOVER_SOUND_PATH_1):
		hover_sounds.append(load(HOVER_SOUND_PATH_1))
	else:
		push_warning("Hover sound 1 not found at: " + HOVER_SOUND_PATH_1)
	
	if FileAccess.file_exists(HOVER_SOUND_PATH_2):
		hover_sounds.append(load(HOVER_SOUND_PATH_2))
	else:
		push_warning("Hover sound 2 not found at: " + HOVER_SOUND_PATH_2)
	
	if FileAccess.file_exists(HOVER_SOUND_PATH_3):
		hover_sounds.append(load(HOVER_SOUND_PATH_3))
	else:
		push_warning("Hover sound 3 not found at: " + HOVER_SOUND_PATH_3)
	
	# Load other audio files
	if FileAccess.file_exists(CLICK_SOUND_PATH):
		click_sound = load(CLICK_SOUND_PATH)
	else:
		push_warning("Click sound not found at: " + CLICK_SOUND_PATH)
	
	if FileAccess.file_exists(TOGGLE_ON_SOUND_PATH):
		toggle_on_sound = load(TOGGLE_ON_SOUND_PATH)
	else:
		push_warning("Toggle on sound not found at: " + TOGGLE_ON_SOUND_PATH)
	
	if FileAccess.file_exists(TOGGLE_OFF_SOUND_PATH):
		toggle_off_sound = load(TOGGLE_OFF_SOUND_PATH)
	else:
		push_warning("Toggle off sound not found at: " + TOGGLE_OFF_SOUND_PATH)
	
	# Create audio players and add them to the scene tree
	hover_player = AudioStreamPlayer.new()
	hover_player.bus = "SFX"
	add_child(hover_player)
	
	click_player = AudioStreamPlayer.new()
	click_player.bus = "SFX"
	add_child(click_player)
	
	toggle_player = AudioStreamPlayer.new()
	toggle_player.bus = "SFX"
	add_child(toggle_player)
	
	# Set the audio streams
	if click_sound:
		click_player.stream = click_sound
	if toggle_on_sound:
		toggle_player.stream = toggle_on_sound
	
	if hover_sounds.size() == 0:
		push_warning("No hover sounds loaded!")
	
	print("GlobalButtonSounds initialized with ", hover_sounds.size(), " hover sound variations")
	
	# Connect to scene tree changes to catch new buttons
	get_tree().node_added.connect(_on_node_added)
	
	# Process all existing buttons in the current scene
	_process_existing_buttons()

func _on_node_added(node: Node) -> void:
	# When a new node is added anywhere in the tree, check if it's a button
	if node is BaseButton:
		_connect_button_sounds(node)

func _process_existing_buttons() -> void:
	# Find and connect all buttons that already exist
	var root = get_tree().current_scene
	if root:
		_recursive_connect_buttons(root)

func _recursive_connect_buttons(node: Node) -> void:
	# Recursively find all buttons in the scene tree
	if node is BaseButton:
		_connect_button_sounds(node)
	
	for child in node.get_children():
		_recursive_connect_buttons(child)

func _connect_button_sounds(button: BaseButton) -> void:
	# Avoid connecting the same button twice
	if button in connected_buttons:
		return
	
	connected_buttons[button] = true
	
	# Connect hover sound (mouse enter)
	if not button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.connect(_on_button_hover.bind(button))
	
	# Connect click/press sound
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed.bind(button))
	
	# For toggle buttons (CheckButton, CheckBox), connect toggle sound
	if button is CheckButton or button is CheckBox:
		if not button.toggled.is_connected(_on_button_toggled):
			button.toggled.connect(_on_button_toggled.bind(button))
	
	# Clean up when button is removed from tree
	if not button.tree_exiting.is_connected(_on_button_removed):
		button.tree_exiting.connect(_on_button_removed.bind(button))

func _on_button_hover(button: BaseButton) -> void:
	# Only play hover sound if button is not disabled
	if not button.disabled and hover_sounds.size() > 0:
		# Pick a random hover sound from the array
		var random_sound = hover_sounds[randi() % hover_sounds.size()]
		hover_player.stream = random_sound
		hover_player.play()

func _on_button_pressed(button: BaseButton) -> void:
	# Don't play click sound for toggle buttons (they use toggle sound instead)
	if button is CheckButton or button is CheckBox:
		return
	
	if not button.disabled and click_player.stream:
		click_player.pitch_scale = randf_range(0.9, 1.1)
		click_player.play()

func _on_button_toggled(is_pressed: bool, button: BaseButton) -> void:
	if button.disabled:
		return
	
	# Play different sounds for toggle on/off if available
	if is_pressed and toggle_on_sound:
		toggle_player.stream = toggle_on_sound
		toggle_player.play()
	elif not is_pressed and toggle_off_sound:
		toggle_player.stream = toggle_off_sound
		toggle_player.play()
	elif toggle_player.stream:
		# Fallback to generic toggle sound
		toggle_player.play()

func _on_button_removed(button: BaseButton) -> void:
	# Clean up our tracking dictionary when button is removed
	if button in connected_buttons:
		connected_buttons.erase(button)

# Public function to manually set sounds at runtime if needed
func set_hover_sound(sound: AudioStream) -> void:
	# Add a single hover sound to the array
	if sound and sound not in hover_sounds:
		hover_sounds.append(sound)

func set_click_sound(sound: AudioStream) -> void:
	click_sound = sound
	click_player.stream = sound

func set_toggle_on_sound(sound: AudioStream) -> void:
	toggle_on_sound = sound

func set_toggle_off_sound(sound: AudioStream) -> void:
	toggle_off_sound = sound

# Public function to disable sounds for specific buttons
func exclude_button(button: BaseButton) -> void:
	if button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.disconnect(_on_button_hover)
	if button.pressed.is_connected(_on_button_pressed):
		button.pressed.disconnect(_on_button_pressed)
	if button.toggled.is_connected(_on_button_toggled):
		button.toggled.disconnect(_on_button_toggled)
	
	if button in connected_buttons:
		connected_buttons.erase(button)
