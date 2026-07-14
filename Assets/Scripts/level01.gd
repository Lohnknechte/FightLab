extends Node2D

const CLASS_SELECTION_SCENE = preload("res://src/scenes/class_selection.tscn")
const MAIN_MENU_SCENE := "res://Main_Menu.tscn"

@onready var _player: Character = $TileMapLayer/CharacterBody2D
@onready var _hud = $HUD
@onready var _class_selection = $ClassSelection


func _ready() -> void:
	for point in $SpawnPoints.get_children():
		point.add_to_group("SpawnPoints")
	$DeathZone.body_entered.connect(_on_death_zone_entered)

	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.set_hotbar_enabled(false)

	# Dummy-Spieler bekommt eine Standard-Klasse
	var dummy := $TileMapLayer/CharacterBody2D2
	if dummy and dummy.has_method("set_class"):
		dummy.set_class("Bummer")

	_class_selection.class_selected.connect(_on_class_selected)
	if _class_selection.has_signal("main_menu_requested"):
		_class_selection.main_menu_requested.connect(_on_main_menu_requested)


func _unhandled_input(event: InputEvent) -> void:
	# K: Zurück zur Klassenauswahl (nur wenn kein Selection-Screen bereits offen ist)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			_open_class_selection()


func _open_class_selection() -> void:
	if _class_selection and is_instance_valid(_class_selection):
		return

	# Spieler einfrieren und Hotbar verstecken
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.set_hotbar_enabled(false)

	# Neuen Klassenauswahl-Screen instanziieren
	var new_selection := CLASS_SELECTION_SCENE.instantiate()
	add_child(new_selection)
	_class_selection = new_selection
	_class_selection.class_selected.connect(_on_class_selected)
	if _class_selection.has_signal("main_menu_requested"):
		_class_selection.main_menu_requested.connect(_on_main_menu_requested)


func _on_class_selected(class_id: String) -> void:
	_hud.connect_to_player(_player)
	_player.set_class(class_id)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_hotbar_enabled(true)

	# Dummy bekommt dieselbe Klasse
	var dummy := $TileMapLayer/CharacterBody2D2
	if dummy and dummy.has_method("set_class"):
		dummy.set_class(class_id)


func _on_main_menu_requested() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_death_zone_entered(body: Node2D) -> void:
	if not body.has_method("die"):
		return
	if body.has_method("is_dead") and body.is_dead():
		return
	body.die()
