extends Control

signal back
signal loadout_requested

@onready var name_label: Label = $Center/Panel/Margin/Layout/Header/Row/Identity/NameValue
@onready var level_label: Label = $Center/Panel/Margin/Layout/Header/Row/LevelBadge/LevelValue


func _ready() -> void:
	visible = false
	$Center/Panel/Margin/Layout/Footer/Back.pressed.connect(_on_back)
	$Center/Panel/Margin/Layout/Header/Row/Loadout.pressed.connect(_on_loadout)


func open() -> void:
	name_label.text = "Player"
	level_label.text = "17"
	visible = true
	$Center/Panel/Margin/Layout/Header/Row/Loadout.grab_focus()


func _on_back() -> void:
	visible = false
	back.emit()


func _on_loadout() -> void:
	visible = false
	loadout_requested.emit()
