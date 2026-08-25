extends Control

signal back
signal join_requested

const PLACEHOLDER_SERVERS := [
	{
		"name": "Training Lobby",
		"host": "Alex",
		"players": "1 / 4",
		"level": "Arena 01",
		"mode": "Free For All",
		"region": "EU",
	},
	{
		"name": "Beginner Battles",
		"host": "Sam",
		"players": "2 / 4",
		"level": "Arena 01",
		"mode": "Free For All",
		"region": "EU",
	},
	{
		"name": "Quick Match Room",
		"host": "Jamie",
		"players": "3 / 4",
		"level": "Arena 01",
		"mode": "Free For All",
		"region": "US",
	},
]

@onready var server_list: VBoxContainer = $Center/Panel/Margin/Layout/ServerScroll/ServerList
@onready var selection_label: Label = $Center/Panel/Margin/Layout/Selection
@onready var join_button: Button = $Center/Panel/Margin/Layout/Footer/Join

var _server_buttons: Array[Button]
var _selected_server := -1


func _ready() -> void:
	visible = false
	$Center/Panel/Margin/Layout/Footer/Back.pressed.connect(_on_back)
	join_button.pressed.connect(_join_selected)
	_build_server_list()


func open() -> void:
	visible = true
	_select_server(0)
	_server_buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _build_server_list() -> void:
	for child in server_list.get_children():
		child.free()
	_server_buttons.clear()

	for index in PLACEHOLDER_SERVERS.size():
		var server: Dictionary = PLACEHOLDER_SERVERS[index]
		var button := Button.new()
		button.name = "Server%d" % (index + 1)
		button.text = "%s\nHost: %s    Players: %s    Level: %s    Mode: %s    Region: %s" % [server.name, server.host, server.players, server.level, server.mode, server.region]
		button.custom_minimum_size = Vector2(0, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.pressed.connect(_select_server.bind(index))
		server_list.add_child(button)
		_server_buttons.append(button)


func _select_server(index: int) -> void:
	_selected_server = index
	for button_index in _server_buttons.size():
		_server_buttons[button_index].button_pressed = button_index == index
	var server: Dictionary = PLACEHOLDER_SERVERS[index]
	selection_label.text = "Selected: %s - %s" % [server.name, server.level]
	join_button.disabled = false


func _join_selected() -> void:
	if _selected_server < 0:
		return
	visible = false
	join_requested.emit()


func _on_back() -> void:
	visible = false
	back.emit()
