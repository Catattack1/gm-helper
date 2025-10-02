# InitiativeTracker.gd

extends Control

const CHARACTER_WIDGET_SCENE = preload("res://Scenes/character_widget.tscn")

@onready var initiative_list = $PanelContainer/MarginContainer/HBoxContainer/ScrollContainer/VBoxContainer

var initiative_entries: Array = []
var current_turn_index: int = 0

func _ready():
	print("=== InitiativeTracker Ready ===")
	print("This node name: ", name)
	print("This node type: ", get_class())
	
	print("\n--- SCENE TREE STRUCTURE ---")
	_print_tree_structure(self, 0)
	print("----------------------------\n")
	
	print("Attempting to get initiative_list...")
	print("Initiative list node: ", initiative_list)
	print("Initiative list path: ", initiative_list.get_path() if initiative_list else "NULL")
	print("CHARACTER_WIDGET_SCENE loaded: ", CHARACTER_WIDGET_SCENE != null)
	
	if not initiative_list:
		push_error("CRITICAL: initiative_list is null! Check node path!")
		push_error("Look at the SCENE TREE STRUCTURE above to find the correct path")
		push_error("Then update line 8 in the script with the correct path")
	
	var add_button = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character buttons/add")
	if add_button:
		add_button.pressed.connect(_on_add_button_pressed)
		print("Add button connected!")
	else:
		push_error("Could not find add button!")
	
	print("===============================")

func _print_tree_structure(node: Node, indent: int) -> void:
	var indent_str = ""
	for i in range(indent):
		indent_str += "  "
	
	print(indent_str + "├─ " + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		_print_tree_structure(child, indent + 1)

func _on_add_button_pressed() -> void:
	print("\n=== ADD BUTTON PRESSED ===")
	
	var name_input = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character Name MarginContainer/HBoxContainer/LineEdit")
	var hp_spinbox = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character HP MarginContainer/HBoxContainer/HP SpinBox")
	var temp_hp_spinbox = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character HP MarginContainer/HBoxContainer/Temp HP SpinBox")
	var class_input = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character Class MarginContainer/HBoxContainer/LineEdit")
	var initiative_spinbox = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character Initiative MarginContainer/HBoxContainer/SpinBox")
	var ac_spinbox = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Build a Character VBoxContainer/VBoxContainer/Character Initiative MarginContainer/HBoxContainer/AC SpinBox")
	
	if not name_input or not hp_spinbox or not temp_hp_spinbox or not class_input or not initiative_spinbox or not ac_spinbox:
		push_error("Could not find one or more input fields!")
		return
	
	var char_name = name_input.text if name_input.text != "" else "Unnamed"
	var char_type = class_input.text if class_input.text != "" else "Unknown"
	var hp_value = int(hp_spinbox.value)
	var temp_hp_value = int(temp_hp_spinbox.value)
	var initiative_value = int(initiative_spinbox.value)
	var ac_value = int(ac_spinbox.value)
	
	print("Calling add_to_initiative with values:")
	print("  Name: ", char_name)
	print("  Type: ", char_type)
	print("  Initiative: ", initiative_value)
	print("  HP: ", hp_value)
	print("  Temp HP: ", temp_hp_value)
	print("  AC: ", ac_value)
	
	add_to_initiative(char_name, char_type, initiative_value, hp_value, temp_hp_value, ac_value)
	
	print("=========================\n")

func add_to_initiative(character_name: String, character_type: String, initiative_value: int, hp: int, temp_hp: int = 0, ac: int = 0) -> void:
	print("\n=== ADD TO INITIATIVE ===")
	print("Name: ", character_name)
	
	var entry_data = {
		"name": character_name,
		"type": character_type,
		"initiative": initiative_value,
		"hp": hp,
		"max_hp": hp,
		"temp_hp": temp_hp,
		"ac": ac,
		"is_active": false,
		"widget": null
	}
	
	initiative_entries.append(entry_data)
	print("Total entries after add: ", initiative_entries.size())
	
	sort_initiative()
	rebuild_ui()
	print("========================\n")

func sort_initiative() -> void:
	print("--- Sorting initiative ---")
	initiative_entries.sort_custom(func(a, b): return a.initiative > b.initiative)

func rebuild_ui() -> void:
	print("\n--- REBUILD UI ---")
	
	if not initiative_list:
		push_error("CRITICAL: initiative_list is null! Cannot rebuild UI!")
		return
	
	for child in initiative_list.get_children():
		child.queue_free()
	
	for i in range(initiative_entries.size()):
		var entry = initiative_entries[i]
		var widget = create_character_widget(entry, i)
		
		if widget:
			entry.widget = widget
			initiative_list.add_child(widget)
		else:
			push_error("Failed to create widget for: ", entry.name)
	
	# Emit signal that initiative was rebuilt
	if GlobalSignals:
		GlobalSignals.initiative_rebuilt.emit()
		print("Emitted initiative_rebuilt signal")
	else:
		push_error("GlobalSignals not available in InitiativeTracker!")
	
	print("--- END REBUILD UI ---\n")

func create_character_widget(entry: Dictionary, index: int) -> Control:
	if not CHARACTER_WIDGET_SCENE:
		push_error("CHARACTER_WIDGET_SCENE is null!")
		return null
	
	var widget = CHARACTER_WIDGET_SCENE.instantiate()
	
	if not widget:
		push_error("Failed to instantiate CHARACTER_WIDGET_SCENE!")
		return null
	
	if widget.has_method("set_character_index"):
		widget.set_character_index(index)
	
	populate_widget(widget, entry, index)
	
	return widget

func populate_widget(widget: Control, entry: Dictionary, index: int) -> void:
	var name_label = widget.get_node_or_null("VBoxContainer/Name_Type_HBoxContainer/Name_Label")
	var type_label = widget.get_node_or_null("VBoxContainer/Name_Type_HBoxContainer/Type_Label")
	var hp_label = widget.get_node_or_null("VBoxContainer/Health_HBoxContainer/HP_Label")
	var temp_hp_label = widget.get_node_or_null("VBoxContainer/Health_HBoxContainer/Temp_HP_Label")
	var ac_label = widget.get_node_or_null("VBoxContainer/Initiative_AC_HBoxContainer/AC_Label")
	var initiative_label = widget.get_node_or_null("VBoxContainer/Initiative_AC_HBoxContainer/Initiative_Label")
	
	if name_label:
		name_label.text = entry.name
	if type_label:
		type_label.text = entry.type
	if hp_label:
		hp_label.text = str(entry.hp) + "/" + str(entry.max_hp)
	if temp_hp_label:
		temp_hp_label.text = "Temp HP: " + str(entry.temp_hp)
	if ac_label:
		ac_label.text = "AC: " + str(entry.ac)
	if initiative_label:
		initiative_label.text = "Initiative: " + str(entry.initiative)
	
	if entry.is_active:
		var panel = widget as PanelContainer
		if panel:
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = Color(0.3, 0.5, 0.8, 0.3)
			stylebox.border_color = Color(0.5, 0.7, 1.0)
			stylebox.set_border_width_all(2)
			panel.add_theme_stylebox_override("panel", stylebox)

func next_turn() -> void:
	if initiative_entries.is_empty():
		return
	
	if current_turn_index < initiative_entries.size():
		initiative_entries[current_turn_index].is_active = false
	
	current_turn_index = (current_turn_index + 1) % initiative_entries.size()
	initiative_entries[current_turn_index].is_active = true
	
	rebuild_ui()

func previous_turn() -> void:
	if initiative_entries.is_empty():
		return
	
	if current_turn_index < initiative_entries.size():
		initiative_entries[current_turn_index].is_active = false
	
	current_turn_index = (current_turn_index - 1 + initiative_entries.size()) % initiative_entries.size()
	initiative_entries[current_turn_index].is_active = true
	
	rebuild_ui()

func update_hp(index: int, new_hp: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		initiative_entries[index].hp = clamp(new_hp, 0, initiative_entries[index].max_hp)
		_emit_hp_changed(index)
		_update_widget_hp(index)

func update_temp_hp(index: int, new_temp_hp: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		initiative_entries[index].temp_hp = max(0, new_temp_hp)
		_emit_hp_changed(index)
		_update_widget_hp(index)

func apply_damage(index: int, damage: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		var entry = initiative_entries[index]
		
		if entry.temp_hp > 0:
			if damage >= entry.temp_hp:
				damage -= entry.temp_hp
				entry.temp_hp = 0
				entry.hp = max(0, entry.hp - damage)
			else:
				entry.temp_hp -= damage
		else:
			entry.hp = max(0, entry.hp - damage)
		
		_emit_hp_changed(index)
		_update_widget_hp(index)

func heal_character(index: int, heal_amount: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		var entry = initiative_entries[index]
		entry.hp = min(entry.max_hp, entry.hp + heal_amount)
		
		_emit_hp_changed(index)
		_update_widget_hp(index)

# Helper function to emit HP changed signal
func _emit_hp_changed(index: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		var entry = initiative_entries[index]
		print("Emitting character_hp_changed for index ", index)
		if GlobalSignals:
			GlobalSignals.character_hp_changed.emit(index, entry.hp, entry.max_hp, entry.temp_hp)
		else:
			push_error("GlobalSignals not available!")

# Helper function to update widget HP labels
func _update_widget_hp(index: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		var entry = initiative_entries[index]
		if entry.widget:
			var hp_label = entry.widget.get_node_or_null("VBoxContainer/Health_HBoxContainer/HP_Label")
			var temp_hp_label = entry.widget.get_node_or_null("VBoxContainer/Health_HBoxContainer/Temp_HP_Label")
			
			if hp_label:
				hp_label.text = str(entry.hp) + "/" + str(entry.max_hp)
			if temp_hp_label:
				temp_hp_label.text = "Temp HP: " + str(entry.temp_hp)

func remove_character(index: int) -> void:
	if index >= 0 and index < initiative_entries.size():
		if initiative_entries[index].widget:
			initiative_entries[index].widget.queue_free()
		
		initiative_entries.remove_at(index)
		
		if current_turn_index >= initiative_entries.size():
			current_turn_index = 0
		
		rebuild_ui()

func clear_initiative() -> void:
	for entry in initiative_entries:
		if entry.widget:
			entry.widget.queue_free()
	
	initiative_entries.clear()
	current_turn_index = 0

func get_character(index: int) -> Dictionary:
	if index >= 0 and index < initiative_entries.size():
		return initiative_entries[index]
	return {}

func get_current_character() -> Dictionary:
	if current_turn_index >= 0 and current_turn_index < initiative_entries.size():
		return initiative_entries[current_turn_index]
	return {}

func get_all_characters() -> Array:
	return initiative_entries
