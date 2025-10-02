
extends Node2D

# Audio bus indices (these match Godot's audio bus layout)
const BUS_MASTER = 0
const BUS_MUSIC = 1
const BUS_SFX = 2

# Volume sliders
@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider

# Mute checkboxes
@export var master_mute: CheckButton
@export var music_mute: CheckButton
@export var sfx_mute: CheckButton

# Store the volume before muting so we can restore it
var master_volume_before_mute: float = 0.0
var music_volume_before_mute: float = 0.0
var sfx_volume_before_mute: float = 0.0

func _ready() -> void:
	# Load saved settings or set defaults
	_load_audio_settings()
	
	# Connect slider signals
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect checkbox signals
	if master_mute:
		master_mute.toggled.connect(_on_master_mute_toggled)
	
	if music_mute:
		music_mute.toggled.connect(_on_music_mute_toggled)
	
	if sfx_mute:
		sfx_mute.toggled.connect(_on_sfx_mute_toggled)
	
	print("Settings initialized")

# ============================================================================
# SLIDER CALLBACKS
# ============================================================================

func _on_master_volume_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(BUS_MASTER, db)
	_save_audio_settings()
	print("Master volume: ", value, "% (", db, " dB)")

func _on_music_volume_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(BUS_MUSIC, db)
	_save_audio_settings()
	print("Music volume: ", value, "% (", db, " dB)")

func _on_sfx_volume_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(BUS_SFX, db)
	_save_audio_settings()
	print("SFX volume: ", value, "% (", db, " dB)")

# ============================================================================
# MUTE CHECKBOX CALLBACKS
# ============================================================================

func _on_master_mute_toggled(is_muted: bool) -> void:
	if is_muted:
		# Save current volume and mute
		master_volume_before_mute = master_slider.value if master_slider else 100.0
		AudioServer.set_bus_mute(BUS_MASTER, true)
		print("Master muted")
	else:
		# Unmute and restore volume
		AudioServer.set_bus_mute(BUS_MASTER, false)
		if master_slider:
			master_slider.value = master_volume_before_mute
		print("Master unmuted")
	_save_audio_settings()

func _on_music_mute_toggled(is_muted: bool) -> void:
	if is_muted:
		music_volume_before_mute = music_slider.value if music_slider else 100.0
		AudioServer.set_bus_mute(BUS_MUSIC, true)
		print("Music muted")
	else:
		AudioServer.set_bus_mute(BUS_MUSIC, false)
		if music_slider:
			music_slider.value = music_volume_before_mute
		print("Music unmuted")
	_save_audio_settings()

func _on_sfx_mute_toggled(is_muted: bool) -> void:
	if is_muted:
		sfx_volume_before_mute = sfx_slider.value if sfx_slider else 100.0
		AudioServer.set_bus_mute(BUS_SFX, true)
		print("SFX muted")
	else:
		AudioServer.set_bus_mute(BUS_SFX, false)
		if sfx_slider:
			sfx_slider.value = sfx_volume_before_mute
		print("SFX unmuted")
	_save_audio_settings()

# ============================================================================
# SAVE/LOAD SETTINGS
# ============================================================================

func _save_audio_settings() -> void:
	var config = ConfigFile.new()
	
	# Save volumes
	if master_slider:
		config.set_value("audio", "master_volume", master_slider.value)
	if music_slider:
		config.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider:
		config.set_value("audio", "sfx_volume", sfx_slider.value)
	
	# Save mute states
	if master_mute:
		config.set_value("audio", "master_mute", master_mute.button_pressed)
	if music_mute:
		config.set_value("audio", "music_mute", music_mute.button_pressed)
	if sfx_mute:
		config.set_value("audio", "sfx_mute", sfx_mute.button_pressed)
	
	config.save("user://settings.cfg")

func _load_audio_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		# No saved settings, use defaults
		_set_default_volumes()
		return
	
	# Load and apply master volume
	var master_vol = config.get_value("audio", "master_volume", 100.0)
	if master_slider:
		master_slider.value = master_vol
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(master_vol / 100.0))
	
	# Load and apply music volume
	var music_vol = config.get_value("audio", "music_volume", 100.0)
	if music_slider:
		music_slider.value = music_vol
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(music_vol / 100.0))
	
	# Load and apply SFX volume
	var sfx_vol = config.get_value("audio", "sfx_volume", 100.0)
	if sfx_slider:
		sfx_slider.value = sfx_vol
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(sfx_vol / 100.0))
	
	# Load and apply mute states
	if master_mute:
		master_mute.button_pressed = config.get_value("audio", "master_mute", false)
		AudioServer.set_bus_mute(BUS_MASTER, master_mute.button_pressed)
	
	if music_mute:
		music_mute.button_pressed = config.get_value("audio", "music_mute", false)
		AudioServer.set_bus_mute(BUS_MUSIC, music_mute.button_pressed)
	
	if sfx_mute:
		sfx_mute.button_pressed = config.get_value("audio", "sfx_mute", false)
		AudioServer.set_bus_mute(BUS_SFX, sfx_mute.button_pressed)
	
	print("Audio settings loaded")

func _set_default_volumes() -> void:
	# Set all volumes to 100% by default
	if master_slider:
		master_slider.value = 100.0
	if music_slider:
		music_slider.value = 100.0
	if sfx_slider:
		sfx_slider.value = 100.0
	
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(1.0))
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(1.0))
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(1.0))
	
	print("Default audio settings applied")

# Helper function to convert linear volume to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0  # Minimum volume
	return 20.0 * log(linear) / log(10.0)
