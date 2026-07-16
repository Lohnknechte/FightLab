extends Control # Attached to AmmoDisplay

# Since this script is ON AmmoDisplay, use direct paths
@onready var weapon_label: Label = $AmmoDisplay/WeaponLabel
@onready var ammo_icons: HBoxContainer = $AmmoDisplay/AmmoIcons
@onready var status_bar: ProgressBar = $AmmoDisplay/StatusBar

func setup(player: CharacterBody2D) -> void:
	player.weapon_hud_changed.connect(_on_weapon_hud_changed)
	
	if player.has_method("get_active_weapon_hud_state"):
		_on_weapon_hud_changed(player.get_active_weapon_hud_state())

func _on_weapon_hud_changed(state: Dictionary) -> void:
	self.visible = state.get("visible", false)
	if not self.visible: return

	weapon_label.text = state.get("label", "Unknown")
	
	var mode = state.get("mode", "ammo")
	
	if mode == "ammo":
		ammo_icons.visible = true
		status_bar.visible = false
		# FIX: Pass the WHOLE dictionary, not separate args
		_update_ammo_icons(state)
	else:
		ammo_icons.visible = false
		status_bar.visible = true
		status_bar.value = state.get("bar_progress", 0.0) * 100.0
		
func _update_ammo_icons(state: Dictionary) -> void:
	# Clear old icons
	for child in ammo_icons.get_children():
		child.queue_free()
		
	# Extract dynamic icons directly from the state dictionary
	var full_texture = state.get("full_icon")
	var empty_texture = state.get("empty_icon")
	var current = int(state.get("ammo", 0))
	var max_ammo = int(state.get("max_ammo", 0))
	
	# Guard: If no textures are passed, don't crash
	if not full_texture or not empty_texture:
		return
	
	# Build the row
	for i in range(max_ammo):
		var icon = TextureRect.new()
		icon.texture = full_texture if i < current else empty_texture
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ammo_icons.add_child(icon)
