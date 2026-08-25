extends Control

const QUICK_JOIN_SCENE := "res://src/scenes/level01.tscn"

@onready var loadout_menu: Control = $LoadoutMenu

var _main_controls: Array[CanvasItem]


func _ready() -> void:
	_main_controls = [
		$Create_Button,
		$Join_Button,
		$Loadout_Button,
		$Level_Button,
		$Quit_Button,
		$Quick_Button,
		$Label,
		$Label2,
	]
	$Loadout_Button.pressed.connect(_open_loadout)
	$Quick_Button.pressed.connect(_quick_join)
	loadout_menu.confirmed.connect(_close_loadout)
	loadout_menu.cancelled.connect(_close_loadout)
	loadout_menu.visible = false


func _open_loadout() -> void:
	_set_main_controls_visible(false)
	loadout_menu.open()


func _quick_join() -> void:
	get_tree().change_scene_to_file(QUICK_JOIN_SCENE)


func _close_loadout() -> void:
	loadout_menu.visible = false
	_set_main_controls_visible(true)
	$Loadout_Button.grab_focus()


func _set_main_controls_visible(is_visible: bool) -> void:
	for control in _main_controls:
		control.visible = is_visible
