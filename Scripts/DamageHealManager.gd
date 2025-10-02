# DamageHealManager.gd

extends VBoxContainer

@onready var damage_button = $VBoxContainer/HBoxContainer/Damage_Button
@onready var heal_button = $VBoxContainer/HBoxContainer/Heal_Button
@onready var damage_spinbox = $VBoxContainer/HBoxContainer/SpinBox
@onready var hp_label = $VBoxContainer/PanelContainer/HBoxContainer/HpLabel
@onready var current_hp_label = $VBoxContainer/PanelContainer/HBoxContainer/Label
@onready var temp_hp_label = $VBoxContainer/PanelContainer/HBoxContainer/Label2

var initiative_tracker: Node = null
var selected_character_index: int = -1

func _ready():
	print("=== DamageHealManager Ready ===")
	
	initiative_tracker = get_node("/root/Initiative Tracker")
	
	if not initiative_tracker:
		push_error("Could not find Initiative Tracker node!")
		return
	
	print("Initiative Tracker found: ", initiative_tracker)
	
	if damage_button:
		damage_button.pressed.connect(_on_damage_button_pressed)
		print("Damage button connected")
	else:
		push_error("Damage button not found!")
	
	if heal_button:
		heal_button.pressed.connect(_on_heal_button_pressed)
		print("Heal button connected")
	else:
		push_error("Heal button not found!")
	
	if damage_spinbox:
		damage_spinbox.value = 1
		damage_spinbox.min_value = 0
		damage_spinbox.max_value = 999
		damage_spinbox.step = 1
	
	# Connect to global signals
	if GlobalSignals:
		GlobalSignals.character_hp_changed.connect(_on_character_hp_changed)
		GlobalSignals.character_selected.connect(_on_character_selected_signal)
		GlobalSignals.character_deselected.connect(_on_character_deselected_signal)
		GlobalSignals.initiative_rebuilt.connect(_on_initiative_rebuilt)
		print("Connected to GlobalSignals")
	else:
		push_error("GlobalSignals autoload not found!")
	
	update_button_states()
	update_display()
	
	print("================================")

# Called when HP changes for any character
func _on_character_hp_changed(index: int, hp: int, max_hp: int, temp_hp: int) -> void:
	# If this is the selected character, update the display
	if index == selected_character_index:
		update_display()

# Called when a character is selected via signal
func _on_character_selected_signal(index: int) -> void:
	select_character(index)

# Called when character is deselected via signal
func _on_character_deselected_signal() -> void:
	deselect_character()

# Called when initiative list is rebuilt
func _on_initiative_rebuilt() -> void:
	# If we had a character selected, check if it still exists
	if selected_character_index >= 0:
		var character = initiative_tracker.get_character(selected_character_index)
		if character.is_empty():
			# Character no longer exists at this index
			deselect_character()
		else:
			# Update display with current data
			update_display()

# This is called by CharacterWidget when clicked
func on_character_clicked(index: int) -> void:
	print("!!! on_character_clicked called with index: ", index)
	select_character(index)
	# Emit signal so other systems can react
	if GlobalSignals:
		print("Emitting character_selected signal")
		GlobalSignals.character_selected.emit(index)
	else:
		push_error("GlobalSignals not available!")

func select_character(index: int) -> void:
	print("\n=== Character Selected ===")
	print("Index: ", index)
	selected_character_index = index
	update_display()
	update_button_states()
	print("=========================\n")

func deselect_character() -> void:
	print("Character deselected")
	selected_character_index = -1
	update_display()
	update_button_states()

func update_display() -> void:
	if selected_character_index < 0 or not initiative_tracker:
		if hp_label:
			hp_label.text = "Select a character"
		if current_hp_label:
			current_hp_label.text = ""
		if temp_hp_label:
			temp_hp_label.text = ""
		return
	
	var character = initiative_tracker.get_character(selected_character_index)
	
	if character.is_empty():
		hp_label.text = "Invalid character"
		current_hp_label.text = ""
		temp_hp_label.text = ""
		return
	
	if hp_label:
		hp_label.text = character.name
	
	if current_hp_label:
		current_hp_label.text = "HP: " + str(character.hp) + "/" + str(character.max_hp)
	
	if temp_hp_label:
		temp_hp_label.text = "Temp: " + str(character.temp_hp)

func update_button_states() -> void:
	var has_selection = selected_character_index >= 0
	
	if damage_button:
		damage_button.disabled = not has_selection
	
	if heal_button:
		heal_button.disabled = not has_selection

func _on_damage_button_pressed() -> void:
	if selected_character_index < 0 or not initiative_tracker:
		print("No character selected or no initiative tracker!")
		return
	
	var damage_amount = int(damage_spinbox.value)
	
	print("\n=== Applying Damage ===")
	print("Character index: ", selected_character_index)
	print("Damage amount: ", damage_amount)
	
	initiative_tracker.apply_damage(selected_character_index, damage_amount)
	
	# Display will auto-update via signal
	print("=======================\n")

func _on_heal_button_pressed() -> void:
	if selected_character_index < 0 or not initiative_tracker:
		print("No character selected or no initiative tracker!")
		return
	
	var heal_amount = int(damage_spinbox.value)
	
	print("\n=== Applying Heal ===")
	print("Character index: ", selected_character_index)
	print("Heal amount: ", heal_amount)
	
	initiative_tracker.heal_character(selected_character_index, heal_amount)
	
	# Display will auto-update via signal
	print("=====================\n")
