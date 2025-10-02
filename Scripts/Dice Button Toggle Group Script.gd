
extends Container

@onready var d4_button = $D4Button
@onready var d6_button = $D6Button
@onready var d8_button = $D8Button
@onready var d10_button = $D10Button
@onready var d12_button = $D12Button
@onready var d20_button = $"20Button"

var dice_buttons = []
var currently_selected: Button = null

func _ready() -> void:
	# Collect all dice buttons
	dice_buttons = [d4_button, d6_button, d8_button, d10_button, d12_button, d20_button]
	
	# Make sure they're toggle buttons
	for button in dice_buttons:
		if button:
			button.toggle_mode = true
			button.toggled.connect(_on_dice_button_toggled.bind(button))

func _on_dice_button_toggled(is_pressed: bool, button: Button) -> void:
	if is_pressed:
		# This button was just pressed - turn off all others
		for other_button in dice_buttons:
			if other_button and other_button != button:
				other_button.button_pressed = false
		
		currently_selected = button
		
	else:
		# Button was untoggled
		if currently_selected == button:
			currently_selected = null
			

# Optional: Get which dice type is currently selected
func get_selected_dice() -> String:
	if currently_selected == null:
		return ""
	
	match currently_selected:
		d4_button: return "D4"
		d6_button: return "D6"
		d8_button: return "D8"
		d10_button: return "D10"
		d12_button: return "D12"
		d20_button: return "D20"
		_: return ""
