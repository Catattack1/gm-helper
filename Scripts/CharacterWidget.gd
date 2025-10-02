# CharacterWidget.gd

extends Control

var character_index: int = -1
var damage_heal_manager: Node = null

var is_selected: bool = false
var is_hovered: bool = false
@onready var panel = $PanelContainer

func _ready():
	print("\n=== CharacterWidget Ready ===")
	print("Widget name: ", name)
	print("Widget path: ", get_path())
	
	damage_heal_manager = get_node_or_null("/root/Initiative Tracker/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/Build a Enemy_NPC_player VBoxContainer/Damage handler  b\\VBoxContainer")
	
	if not damage_heal_manager:
		push_error("Could not find DamageHealManager!")
	else:
		print("DamageHealManager found: ", damage_heal_manager.name)
	
	if panel:
		print("Panel found: ", panel.name)
	else:
		push_error("PanelContainer not found!")
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect to signals for visual feedback
	GlobalSignals.character_selected.connect(_on_any_character_selected)
	GlobalSignals.character_deselected.connect(_on_any_character_deselected)
	GlobalSignals.character_hp_changed.connect(_on_character_hp_changed)
	
	print("Mouse filter set to STOP")
	print("============================\n")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("\n=== Widget Clicked (via _gui_input) ===")
			print("Character index: ", character_index)
			_on_clicked()
			accept_event()

func set_character_index(index: int) -> void:
	character_index = index
	print("Character index set to: ", index)

func _on_clicked() -> void:
	print("_on_clicked called for index: ", character_index)
	print("damage_heal_manager exists: ", damage_heal_manager != null)
	
	if damage_heal_manager and character_index >= 0:
		if damage_heal_manager.has_method("on_character_clicked"):
			print("Calling on_character_clicked...")
			damage_heal_manager.on_character_clicked(character_index)
			print("on_character_clicked completed")
		else:
			push_error("DamageHealManager doesn't have 'on_character_clicked' method!")
			print("Available methods: ", damage_heal_manager.get_method_list())
	else:
		print("Cannot select - missing manager or invalid index")
		print("  Manager: ", damage_heal_manager)
		print("  Index: ", character_index)
	
	print("=====================\n")

# Called when ANY character is selected (via signal)
func _on_any_character_selected(index: int) -> void:
	if index == character_index:
		set_selected(true)
	else:
		set_selected(false)

# Called when character is deselected (via signal)
func _on_any_character_deselected() -> void:
	set_selected(false)

# Called when HP changes for any character
func _on_character_hp_changed(index: int, hp: int, max_hp: int, temp_hp: int) -> void:
	# If this is our character, update the display
	if index == character_index:
		var hp_label = get_node_or_null("VBoxContainer/Health_HBoxContainer/HP_Label")
		var temp_hp_label = get_node_or_null("VBoxContainer/Health_HBoxContainer/Temp_HP_Label")
		
		if hp_label:
			hp_label.text = str(hp) + "/" + str(max_hp)
		if temp_hp_label:
			temp_hp_label.text = "Temp HP: " + str(temp_hp)

func _mouse_enter() -> void:
	is_hovered = true
	if not is_selected:
		_apply_hover_style()

func _mouse_exit() -> void:
	is_hovered = false
	if not is_selected:
		_apply_normal_style()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_mouse_enter()
		NOTIFICATION_MOUSE_EXIT:
			_mouse_exit()

func set_selected(selected: bool) -> void:
	is_selected = selected
	
	if selected:
		_apply_selected_style()
	else:
		if is_hovered:
			_apply_hover_style()
		else:
			_apply_normal_style()

func _apply_normal_style() -> void:
	if panel:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		stylebox.border_color = Color(0.4, 0.4, 0.4)
		stylebox.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", stylebox)

func _apply_hover_style() -> void:
	if panel:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.3, 0.3, 0.35, 0.9)
		stylebox.border_color = Color(0.6, 0.6, 0.7)
		stylebox.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", stylebox)

func _apply_selected_style() -> void:
	if panel:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.2, 0.4, 0.6, 0.9)
		stylebox.border_color = Color(0.4, 0.7, 1.0)
		stylebox.set_border_width_all(3)
		panel.add_theme_stylebox_override("panel", stylebox)
