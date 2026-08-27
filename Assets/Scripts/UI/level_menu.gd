extends Control

signal back
signal level_selected(level_path: String)

const LEVELS := {
	"Level01": "res://src/scenes/level01.tscn",
	"Level02": "res://src/scenes/Level02/level02.tscn",
	"Level03": "res://src/scenes/Level03/level03.tscn",
}


func _ready() -> void:
	visible = false
	$Center/Panel/Margin/Layout/LevelList/Level01.pressed.connect(_on_level_pressed.bind("Level01"))
	$Center/Panel/Margin/Layout/LevelList/Level02.pressed.connect(_on_level_pressed.bind("Level02"))
	$Center/Panel/Margin/Layout/LevelList/Level03.pressed.connect(_on_level_pressed.bind("Level03"))
	$Center/Panel/Margin/Layout/Footer/Back.pressed.connect(_on_back)


func open() -> void:
	visible = true
	$Center/Panel/Margin/Layout/LevelList/Level01.grab_focus()


func _on_level_pressed(level_key: String) -> void:
	visible = false
	level_selected.emit(LEVELS[level_key])


func _on_back() -> void:
	visible = false
	back.emit()
