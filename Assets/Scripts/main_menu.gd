extends Control

const LEVEL_SCENE := "res://src/scenes/level01.tscn"


func _ready() -> void:
	$Create_Button.pressed.connect(_on_start_game)
	$Quick_Button.pressed.connect(_on_start_game)
	$Level_Button.pressed.connect(_on_start_game)
	$Quit_Button.pressed.connect(_on_quit)


func _on_start_game() -> void:
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_quit() -> void:
	get_tree().quit()
