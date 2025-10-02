# Attach this to a Button node
extends Button

@export_file("*.tscn") var target_scene: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if target_scene == "":
		push_error("No target scene set! Set the target_scene export variable in the inspector.")
		return
	
	get_tree().change_scene_to_file(target_scene)
