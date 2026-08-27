extends Control

const QUICK_JOIN_SCENE := "res://src/scenes/level01.tscn"

@onready var loadout_menu: Control = $LoadoutMenu
@onready var profile_menu: Control = $ProfileMenu
@onready var lobby_list: Control = $LobbyList
@onready var level_menu: Control = $LevelMenu

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
	$Level_Button.pressed.connect(_open_profile)
	$Create_Button.pressed.connect(_open_level_menu)
	$Join_Button.pressed.connect(_open_lobby_list)
	$Quick_Button.pressed.connect(_quick_join)
	$Quit_Button.pressed.connect(_quit_game)
	loadout_menu.confirmed.connect(_close_loadout)
	loadout_menu.cancelled.connect(_close_loadout)
	loadout_menu.profile_requested.connect(_open_profile)
	profile_menu.back.connect(_close_profile)
	profile_menu.loadout_requested.connect(_open_loadout)
	lobby_list.back.connect(_close_lobby_list)
	lobby_list.join_requested.connect(_quick_join)
	level_menu.back.connect(_close_level_menu)
	level_menu.level_selected.connect(_on_level_selected)
	loadout_menu.visible = false


func _open_loadout() -> void:
	profile_menu.visible = false
	_set_main_controls_visible(false)
	loadout_menu.open()


func _open_profile() -> void:
	loadout_menu.visible = false
	_set_main_controls_visible(false)
	profile_menu.open()


func _open_lobby_list() -> void:
	_set_main_controls_visible(false)
	lobby_list.open()


func _quick_join() -> void:
	get_tree().change_scene_to_file(QUICK_JOIN_SCENE)


func _quit_game() -> void:
	get_tree().quit()


func _close_loadout() -> void:
	loadout_menu.visible = false
	_set_main_controls_visible(true)
	$Loadout_Button.grab_focus()


func _close_profile() -> void:
	profile_menu.visible = false
	_set_main_controls_visible(true)
	$Level_Button.grab_focus()


func _close_lobby_list() -> void:
	lobby_list.visible = false
	_set_main_controls_visible(true)
	$Join_Button.grab_focus()


func _open_level_menu() -> void:
	_set_main_controls_visible(false)
	level_menu.open()


func _close_level_menu() -> void:
	level_menu.visible = false
	_set_main_controls_visible(true)
	$Create_Button.grab_focus()


func _on_level_selected(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)


func _set_main_controls_visible(is_visible: bool) -> void:
	for control in _main_controls:
		control.visible = is_visible
