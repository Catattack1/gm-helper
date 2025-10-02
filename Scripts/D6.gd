# D6 Dice roller script - attach to a Control node
# This detects which side is closest to camera after rolling
extends Control

@onready var viewport = $PanelContainer/VBoxContainer/SubViewportContainer/SubViewport
@onready var camera = $PanelContainer/VBoxContainer/SubViewportContainer/SubViewport/Camera3D
@onready var dice = $PanelContainer/VBoxContainer/SubViewportContainer/SubViewport/D6
@onready var result_label = $PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/ResultLabel

# Side nodes will be populated in _ready()
var sides = {}

var is_rolling = false
var spin_speed = Vector3.ZERO
var spin_direction = Vector3.ZERO  # Random axis to spin around
var target_rotation = Vector3.ZERO
var roll_time = 0.0
var roll_duration = 2.0
var last_result = 0
var is_centering = false

signal roll_complete(result: int)

func _ready() -> void:
	result_label.text = ""
	
	# Populate sides dictionary and verify all nodes exist
	for i in range(1, 7):
		var side_node = dice.get_node_or_null("Side" + str(i))
		if side_node:
			sides[i] = side_node
		else:
			push_error("Side" + str(i) + " node not found! Make sure all Side1-Side6 nodes exist as children of D6")
	
	if sides.size() != 6:
		push_error("Not all side markers found! Found " + str(sides.size()) + " out of 6")

func _process(delta: float) -> void:
	if is_rolling and not is_centering:
		roll_time += delta
		var progress = roll_time / roll_duration
		
		if progress < 1.0:
			# Spin around the random axis, slowing down
			var speed_multiplier = 1.0 - ease(progress, 0.3)
			var rotation_amount = spin_speed.length() * delta * speed_multiplier
			
			# Rotate around the random spin axis
			dice.rotate(spin_direction, rotation_amount)
		else:
			# Spinning finished, now detect closest side
			_detect_and_center_result()
	
	elif is_centering:
		# Smoothly rotate to center the winning face
		roll_time += delta
		var settle_progress = roll_time / 0.5  # 0.5 second to center
		
		if settle_progress < 1.0:
			dice.rotation = dice.rotation.lerp(target_rotation, settle_progress * settle_progress)
		else:
			dice.rotation = target_rotation
			is_rolling = false
			is_centering = false
			result_label.text = str(last_result)
			roll_complete.emit(last_result)

func _detect_and_center_result():
	if sides.size() != 6:
		push_error("Cannot detect result - not all side markers present!")
		is_rolling = false
		return
	
	var camera_forward = -camera.global_transform.basis.z
	var closest_side = 1
	var closest_dot = -999.0
	
	# Find which side is facing the camera most directly
	for side_num in sides.keys():
		var side_node = sides[side_num]
		if side_node and is_instance_valid(side_node):
			# Get the direction from dice center to this side marker
			var side_direction = (side_node.global_position - dice.global_position).normalized()
			
			# Check how aligned this side is with camera direction
			var dot = side_direction.dot(camera_forward)
			
			if dot > closest_dot:
				closest_dot = dot
				closest_side = side_num
	
	last_result = closest_side
	print("Detected side: ", closest_side)
	
	# Now calculate rotation needed to center this face toward camera
	var side_node = sides[closest_side]
	if side_node and is_instance_valid(side_node):
		var side_direction = (side_node.global_position - dice.global_position).normalized()
		
		# Calculate rotation to align this face with camera
		target_rotation = _calculate_face_alignment(closest_side)
		
		is_centering = true
		roll_time = 0.0
	else:
		push_error("Side node became invalid!")
		is_rolling = false

# Calculate the rotation needed to face a specific side toward the camera
func _calculate_face_alignment(face: int) -> Vector3:
	# Get current rotation and the direction the face should point
	var side_node = sides[face]
	var current_side_dir = (side_node.global_position - dice.global_position).normalized()
	var target_dir = -camera.global_transform.basis.z
	
	# Calculate the rotation axis and angle
	var rotation_axis = current_side_dir.cross(target_dir).normalized()
	var rotation_angle = current_side_dir.angle_to(target_dir)
	
	# Apply rotation to current dice rotation
	if rotation_axis.length() > 0.001:  # Avoid zero-length axis
		var rotation_quat = Quaternion(rotation_axis, rotation_angle)
		var current_quat = Quaternion(dice.transform.basis)
		var final_quat = rotation_quat * current_quat
		return final_quat.get_euler()
	else:
		return dice.rotation

# ============================================================================
# CALL THIS FUNCTION FROM PARENT SCENE TO ROLL THE DICE
# ============================================================================
func roll_dice() -> void:
	if is_rolling:
		return
	
	result_label.text = ""
	
	# Create a completely random rotation axis (normalized direction vector)
	spin_direction = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	# Set consistent speed magnitude
	var speed_magnitude = randf_range(15.0, 20.0)  # Consistent velocity range
	spin_speed = spin_direction * speed_magnitude
	
	# Add a random starting rotation to make each roll unique
	dice.rotation = Vector3(
		randf_range(0, TAU),
		randf_range(0, TAU),
		randf_range(0, TAU)
	)
	
	is_rolling = true
	is_centering = false
	roll_time = 0.0

# Optional: Get result (only valid after roll completes)
func get_last_result() -> int:
	return last_result

# Optional: Check if currently rolling
func is_currently_rolling() -> bool:
	return is_rolling
