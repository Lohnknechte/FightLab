extends Button

func _pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/Level02/level02.tscn")
