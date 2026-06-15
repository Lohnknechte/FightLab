extends CanvasLayer

@onready var health_bar: ProgressBar = $VBoxContainer/HBoxContainer/BarContainer/HealthBar
@onready var ghost_bar: ProgressBar = $VBoxContainer/HBoxContainer/BarContainer/GhostBar
@onready var ammo_display: VBoxContainer = $Hotbar/AmmoDisplay
@onready var weapon_label: Label = $Hotbar/AmmoDisplay/WeaponLabel
@onready var ammo_icons: HBoxContainer = $Hotbar/AmmoDisplay/AmmoIcons
@onready var status_bar: ProgressBar = $Hotbar/AmmoDisplay/StatusBar
@onready var _hotbar_slots: Array[Control] = [
	$Hotbar/PanelContainer/HBoxContainer/Slot1,
	$Hotbar/PanelContainer/HBoxContainer/Slot2,
	$Hotbar/PanelContainer/HBoxContainer/Slot3,
	$Hotbar/PanelContainer/HBoxContainer/Slot4,
	$Hotbar/PanelContainer/HBoxContainer/Slot5,
	$Hotbar/PanelContainer/HBoxContainer/Slot6,
	$Hotbar/PanelContainer/HBoxContainer/Slot7,
	$Hotbar/PanelContainer/HBoxContainer/Slot8,
	$Hotbar/PanelContainer/HBoxContainer/Slot9,
]

var _player: CharacterBody2D
var _ghost_tween: Tween


func connect_to_player(player: CharacterBody2D) -> void:
	_player = player
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	ghost_bar.max_value = player.max_health
	ghost_bar.value = player.current_health
	player.health_changed.connect(_on_health_changed)
	if player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_weapon_changed)
	if player.has_signal("weapon_hud_changed"):
		player.weapon_hud_changed.connect(_on_weapon_hud_changed)
	_set_active_slot(1)
	if player.has_method("get_active_weapon_hud_state"):
		_on_weapon_hud_changed(player.get_active_weapon_hud_state())

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health
	ghost_bar.max_value = max_health

	if _ghost_tween:
		_ghost_tween.kill()

	if new_health >= ghost_bar.value:
		ghost_bar.value = float(new_health)
		return

	_ghost_tween = create_tween()
	_ghost_tween.tween_interval(0.25)
	_ghost_tween.tween_property(ghost_bar, "value", float(new_health), 0.3)


func _on_weapon_changed(slot: int) -> void:
	_set_active_slot(slot)


func _on_weapon_hud_changed(state: Dictionary) -> void:
	var is_visible := bool(state.get("visible", false))
	ammo_display.visible = is_visible
	if not is_visible:
		return

	var mode := str(state.get("mode", ""))
	var label := str(state.get("label", ""))
	weapon_label.text = label

	if mode == "ammo":
		_update_ammo_icons(
			int(state.get("current", 0)),
			int(state.get("max", 0)),
			state.get("full_icon", null),
			state.get("empty_icon", null)
		)
		ammo_icons.visible = true
		status_bar.visible = bool(state.get("bar_visible", false))
		status_bar.value = float(state.get("bar_progress", 0.0)) * 100.0
		return

	if mode == "cooldown":
		_clear_ammo_icons()
		ammo_icons.visible = false
		status_bar.visible = true
		status_bar.value = float(state.get("bar_progress", 0.0)) * 100.0
		return

	_clear_ammo_icons()
	ammo_icons.visible = false
	status_bar.visible = false


func _set_active_slot(slot: int) -> void:
	for i in range(_hotbar_slots.size()):
		var is_active := (i + 1) == slot
		_hotbar_slots[i].modulate = Color(1, 1, 1, 1) if is_active else Color(1, 1, 1, 0.45)


func _update_ammo_icons(current: int, max_ammo: int, full_icon: Texture2D, empty_icon: Texture2D) -> void:
	if ammo_icons.get_child_count() != max_ammo:
		_clear_ammo_icons()
		for _i in range(max_ammo):
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(16, 16)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ammo_icons.add_child(icon)

	for i in range(max_ammo):
		var icon := ammo_icons.get_child(i) as TextureRect
		icon.texture = full_icon if i < current else empty_icon
		icon.modulate = Color(1, 1, 1, 1) if i < current else Color(1, 1, 1, 0.28)


func _clear_ammo_icons() -> void:
	for child in ammo_icons.get_children():
		ammo_icons.remove_child(child)
		child.free()

func _on_take_damage_pressed() -> void:
	if _player:
		_player.take_damage(10)
