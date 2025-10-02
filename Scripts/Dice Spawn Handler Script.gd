# Attach this to the "PanelContainer2" node
extends PanelContainer

# Export the dice scene files
@export_file("*.tscn") var d4_scene: String = ""
@export_file("*.tscn") var d6_scene: String = ""
@export_file("*.tscn") var d8_scene: String = ""
@export_file("*.tscn") var d10_scene: String = ""
@export_file("*.tscn") var d12_scene: String = ""
@export_file("*.tscn") var d20_scene: String = ""

# Reference to the scroll container where dice will spawn
@onready var dice_scroll = $ScrollContainer
@onready var dice_holder = $ScrollContainer/DiceHolder
@onready var number_input = $"../PanelContainer/Selector container/SpinBox"

# Buttons - will be found dynamically
var d4_button: Button
var d6_button: Button
var d8_button: Button
var d10_button: Button
var d12_button: Button
var d20_button: Button
var roll_button: Button
var spawn_button: Button

# Track spawned dice
var spawned_dice = []

func _ready() -> void:
	print("\n==========================================")
	print("=== DICE SPAWN HANDLER INITIALIZING ===")
	print("==========================================")
	
	# Find buttons dynamically
	var root = get_tree().current_scene
	print("Root scene: ", root.name)
	
	print("\n--- Searching for buttons ---")
	d4_button = _find_node_by_name(root, "D4Button")
	d6_button = _find_node_by_name(root, "D6Button")
	d8_button = _find_node_by_name(root, "D8Button")
	d10_button = _find_node_by_name(root, "D10Button")
	d12_button = _find_node_by_name(root, "D12Button")
	d20_button = _find_node_by_name(root, "20Button")
	roll_button = _find_node_by_name(root, "RollButton")
	spawn_button = _find_node_by_name(root, "Spawn Button")
	
	print("D4Button found: ", d4_button != null)
	print("D6Button found: ", d6_button != null)
	print("D8Button found: ", d8_button != null)
	print("D10Button found: ", d10_button != null)
	print("D12Button found: ", d12_button != null)
	print("20Button found: ", d20_button != null)
	print("RollButton found: ", roll_button != null)
	print("Spawn Button found: ", spawn_button != null)
	
	# Verify number input
	print("\n--- Checking number input ---")
	if number_input:
		print("✓ Number input found: ", number_input.name)
		print("  Current value: ", number_input.value)
	else:
		print("✗ ERROR: Number input not found!")
	
	# Connect signals
	print("\n--- Connecting button signals ---")
	if spawn_button:
		spawn_button.pressed.connect(_on_spawn_pressed)
		print("✓ Spawn button connected")
	
	if roll_button:
		roll_button.pressed.connect(_on_roll_all_pressed)
		print("✓ Roll button connected")
	
	# Verify dice holder
	print("\n--- Checking dice holder ---")
	if dice_holder:
		print("✓ Dice holder found: ", dice_holder.name)
		print("  Type: ", dice_holder.get_class())
	else:
		print("✗ ERROR: Dice holder not found!")
	
	print("\n==========================================")
	print("=== INITIALIZATION COMPLETE ===")
	print("==========================================\n")

# Helper function to find nodes by name anywhere in the tree
func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	
	for child in node.get_children():
		var found = _find_node_by_name(child, node_name)
		if found:
			return found
	
	return null

func spawn_dice(scene_path: String, dice_name: String) -> void:
	print("\n========================================")
	print("=== SPAWNING ", dice_name, " ===")
	print("========================================")
	
	if scene_path == "" or scene_path == null:
		print("✗ ERROR: Scene path is empty!")
		push_error(dice_name + " scene not set in inspector!")
		return
	
	if not FileAccess.file_exists(scene_path):
		print("✗ ERROR: File does not exist at: ", scene_path)
		push_error("File not found: " + scene_path)
		return
	
	print("Loading scene: ", scene_path)
	var dice_scene = load(scene_path)
	
	if not dice_scene:
		print("✗ ERROR: Failed to load scene!")
		push_error("Failed to load " + dice_name + " scene")
		return
	
	print("✓ Scene loaded")
	var dice_instance = dice_scene.instantiate()
	
	if not dice_instance:
		print("✗ ERROR: Failed to instantiate!")
		return
	
	print("✓ Dice instantiated")
	
	if not dice_holder:
		print("✗ ERROR: Dice holder is null!")
		dice_instance.queue_free()
		return
	
	# Ensure the dice has a visible size
	if dice_instance is Control:
		if dice_instance.custom_minimum_size == Vector2.ZERO:
			dice_instance.custom_minimum_size = Vector2(200, 200)
		
		var viewport_container = dice_instance.get_node_or_null("SubViewportContainer")
		if viewport_container and viewport_container.custom_minimum_size == Vector2.ZERO:
			viewport_container.custom_minimum_size = Vector2(200, 200)
	
	dice_holder.add_child(dice_instance)
	
	# CRITICAL: Make SubViewport and ALL its contents completely unique
	var subviewport_container = dice_instance.get_node_or_null("SubViewportContainer")
	if subviewport_container:
		var subviewport = subviewport_container.get_node_or_null("SubViewport")
		if subviewport:
			print("Making SubViewport unique...")
			
			# Store original children info
			var original_children = []
			for child in subviewport.get_children():
				original_children.append(child)
			
			# Remove all children from SubViewport
			for child in original_children:
				subviewport.remove_child(child)
			
			# Duplicate each child with FULL recursion to make everything unique
			for child in original_children:
				# Use flags to duplicate EVERYTHING including scripts, signals, groups, etc.
				var duplicated = child.duplicate(DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_USE_INSTANTIATION)
				
				# Also need to make materials unique if it's a MeshInstance3D
				_make_node_resources_unique(duplicated)
				
				subviewport.add_child(duplicated)
				duplicated.name = child.name
				duplicated.owner = subviewport
				
				# Free the original
				child.queue_free()
			
			print("✓ SubViewport made unique with ", subviewport.get_child_count(), " children")
	
	spawned_dice.append(dice_instance)
	
	print("✓✓✓ SUCCESS! Spawned ", dice_name)
	print("Total dice: ", spawned_dice.size())
	print("========================================\n")

# Recursively make all resources unique (materials, meshes, etc.)
func _make_node_resources_unique(node: Node) -> void:
	# Make MeshInstance3D materials unique
	if node is MeshInstance3D:
		if node.mesh:
			node.mesh = node.mesh.duplicate()
		
		# Make all materials unique
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_surface_override_material(i)
			if mat:
				node.set_surface_override_material(i, mat.duplicate())
	
	# Make Light3D resources unique
	elif node is Light3D:
		# Lights don't typically share resources, but we can ensure they're independent
		pass
	
	# Recurse to all children
	for child in node.get_children():
		_make_node_resources_unique(child)

func _on_spawn_pressed() -> void:
	print("\n>>> SPAWN BUTTON PRESSED <<<")
	
	# Clear all existing dice first
	clear_all_dice()
	
	var selected_dice = ""
	var selected_scene = ""
	
	# Check which button is toggled
	if d4_button and d4_button.button_pressed:
		selected_dice = "D4"
		selected_scene = d4_scene
	elif d6_button and d6_button.button_pressed:
		selected_dice = "D6"
		selected_scene = d6_scene
	elif d8_button and d8_button.button_pressed:
		selected_dice = "D8"
		selected_scene = d8_scene
	elif d10_button and d10_button.button_pressed:
		selected_dice = "D10"
		selected_scene = d10_scene
	elif d12_button and d12_button.button_pressed:
		selected_dice = "D12"
		selected_scene = d12_scene
	elif d20_button and d20_button.button_pressed:
		selected_dice = "D20"
		selected_scene = d20_scene
	else:
		print("⚠ No dice button selected!")
		return
	
	# Get number of dice to spawn from the spinbox
	var num_dice = 1
	if number_input:
		num_dice = int(number_input.value)
		print("Spawning ", num_dice, " x ", selected_dice)
	else:
		print("⚠ Number input not found, defaulting to 1 die")
	
	# Spawn the specified number of dice
	for i in range(num_dice):
		spawn_dice(selected_scene, selected_dice)

func _on_roll_all_pressed() -> void:
	if spawned_dice.size() == 0:
		print("No dice to roll!")
		return
	
	print("\n>>> ROLLING ", spawned_dice.size(), " DICE <<<")
	
	# Roll all dice
	for dice in spawned_dice:
		if dice and dice.has_method("roll_dice"):
			dice.roll_dice()
	
	# Wait for animations
	await get_tree().create_timer(2.7).timeout
	
	# Calculate total
	var total = 0
	for dice in spawned_dice:
		if dice and dice.has_method("get_last_result"):
			var result = dice.get_last_result()
			total += result
			print("  Result: ", result)
	
	print(">>> TOTAL: ", total, " <<<\n")
	
	# Update label if it exists - show 0 as "0"
	var label = get_node_or_null("../Label")
	if label and label is Label:
		label.text = "Total: " + str(total)

func clear_all_dice() -> void:
	for dice in spawned_dice:
		if dice:
			dice.queue_free()
	spawned_dice.clear()
	print("Cleared all dice")
