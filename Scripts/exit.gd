extends Button

# This function is called automatically when the button is pressed.
func _pressed() -> void:
	get_tree().quit() # Safely closes the game.
