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

# Gadget HUD (bottom-right, clear of the centered hotbar and top-left health)
@onready var gadget_widget: Control = $GadgetWidget
@onready var gadget_frame: Panel = $GadgetWidget/Frame
@onready var charge_bar: ProgressBar = $GadgetWidget/Frame/ChargeFill
@onready var gadget_icon: Control = $GadgetWidget/Frame/Icon
@onready var reel: Control = $GadgetWidget/Frame/Reel
@onready var reel_strip: Control = $GadgetWidget/Frame/Reel/Strip
@onready var die_badge: Control = $GadgetWidget/DieBadge
@onready var key_hint: Panel = $GadgetWidget/KeyHint
@onready var name_label: Label = $GadgetWidget/NameLabel
@onready var voiceline_label: Label = $VoicelineLabel
@onready var sel_icons: Array = [
	$GadgetWidget/Selector/Sel0,
	$GadgetWidget/Selector/Sel1,
	$GadgetWidget/Selector/Sel2,
]

const GADGET_ORDER := {"Airstrike": 0, "Dash": 1, "Dice": 2}
const DICE_LABELS := ["Heal", "Teleport", "Shockwave", "Swap", "Jackpot", "Snake Eyes"]
const DICE_ICON := {"Heal": 3, "Teleport": 4, "Shockwave": 5, "Swap": 6, "Jackpot": 7, "Snake Eyes": 8}

const FILL_CHARGING := Color(0.88, 0.28, 0.23, 0.55)
const FILL_READY := Color(0.96, 0.74, 0.12, 0.8)
const BORDER_IDLE := Color(0.32, 0.36, 0.45, 1.0)
const BORDER_READY := Color(0.96, 0.74, 0.12, 1.0)
const BORDER_READY_HI := Color(1.0, 0.95, 0.65, 1.0)
const BORDER_DENIED := Color(0.9, 0.25, 0.22, 1.0)
const ICON_IDLE := Color(0.92, 0.94, 1.0)
const ICON_READY := Color(1.0, 0.97, 0.85)
const SEL_ACTIVE := Color(0.96, 0.74, 0.12)
const SEL_INACTIVE := Color(0.55, 0.6, 0.7)

var _player: CharacterBody2D
var _ghost_tween: Tween
var _pulse_tween: Tween
var _voiceline_tween: Tween
var _flash_tween: Tween
var _roll_tween: Tween
var _fill_style: StyleBoxFlat
var _frame_style: StyleBoxFlat
var _is_ready := false
var _dice_result_name := ""
var _current_name := ""
var _ult_is_ready: bool = false  
var _ult_pulse_tween: Tween = null # Must be declared here

# --- UI References (Update paths to match your scene tree) ---
# These nodes do not exist in hud.tscn; the live ultimate display is
# ultimate_hud.gd. get_node_or_null avoids engine errors on instantiation.
@onready var ult_icon: Control = get_node_or_null("UltimateIcon")
@onready var ult_key_hint: Label = get_node_or_null("UltimateKeyHint")
@onready var _ult_fill_style: Control = get_node_or_null("ChargeFill")
@onready var _ult_frame_style: Control = get_node_or_null("ChargeFrame")


func _ready() -> void:
	var fill := charge_bar.get_theme_stylebox("fill")
	if fill is StyleBoxFlat:
		_fill_style = fill
		_fill_style.bg_color = FILL_CHARGING
	var frame := gadget_frame.get_theme_stylebox("panel")
	if frame is StyleBoxFlat:
		_frame_style = frame
		_frame_style.border_color = BORDER_IDLE
	if gadget_icon.has_method("set_icon_color"):
		gadget_icon.set_icon_color(ICON_IDLE)
	key_hint.visible = false
	die_badge.visible = false
	reel.visible = false
	voiceline_label.modulate.a = 0.0
	_update_selector(0)


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

	# Gadgets
	if player.has_signal("gadget_charge_changed"):
		charge_bar.max_value = player.gadget_max_charge
		charge_bar.value = player.gadget_charge
		_apply_gadget(player.get_gadget_name())
		player.gadget_charge_changed.connect(_on_gadget_charge_changed)
		player.gadget_selected.connect(_on_gadget_selected)
		player.gadget_used.connect(_on_gadget_used)
		player.gadget_use_denied.connect(_on_gadget_use_denied)
		player.dice_rolled.connect(_on_dice_rolled)


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


# ---------------------------------------------------------------------------
# Ultimate Hud
# ---------------------------------------------------------------------------
func _on_ultimate_charge_updated(current: float, max: float) -> void:
	# 1. Update the Bar (Assuming charge_bar is your UltimateChargeBar node)
	# If charge_bar is a native ProgressBar, use .value. If custom script, use your variables.
	if charge_bar.has_method("set_charge"): 
		charge_bar.set_charge(current, max)
	else:
		# Fallback for custom script variables
		charge_bar.current_charge = current
		charge_bar.max_charge = max
		charge_bar.queue_redraw()

	# 2. Check Ready State
	var full: bool = current >= max
	if full and not _ult_is_ready:
		_set_ultimate_ready(true)
	elif not full and _ult_is_ready:
		(false)

# State variable (add this at the top of your script with other vars)
	var _ult_is_ready: bool = false
	
func _set_ultimate_ready(ready: bool) -> void:
	_ult_is_ready = ready
	
	# Kill existing tween to prevent conflicts
	if _ult_pulse_tween:
		_ult_pulse_tween.kill()

	if ready:
		# --- VISUALS WHEN READY ---
		# Change Bar Color
		if _ult_fill_style:
			_ult_fill_style.bg_color = FILL_READY # Reuse your gadget color constant
		
		# Change Icon Color (if you have an ultimate icon)
		if ult_icon and ult_icon.has_method("set_icon_color"):
			ult_icon.set_icon_color(ICON_READY)
		
		# Show Key Hint (e.g., "Q")
		if ult_key_hint:
			ult_key_hint.visible = true
			ult_key_hint.modulate.a = 1.0
		
		# Play Pulse Animation (Copy your gadget tween logic)
		_ult_pulse_tween = create_tween().set_loops()
		if _ult_frame_style:
			_ult_pulse_tween.tween_property(_ult_frame_style, "border_color", BORDER_READY_HI, 0.5).set_trans(Tween.TRANS_SINE)
			_ult_pulse_tween.parallel().tween_property(ult_key_hint, "modulate:a", 0.5, 0.5)
		if _ult_frame_style:
			_ult_pulse_tween.tween_property(_ult_frame_style, "border_color", BORDER_READY, 0.5).set_trans(Tween.TRANS_SINE)
		_ult_pulse_tween.parallel().tween_property(ult_key_hint, "modulate:a", 1.0, 0.5)
		
		# Optional: Play a sound
		# $AudioPlayer.play() 

	else:
		# --- VISUALS WHEN CHARGING ---
		if _ult_fill_style:
			_ult_fill_style.bg_color = FILL_CHARGING

		if _ult_frame_style:
			_ult_frame_style.border_color = BORDER_IDLE
 
		if ult_key_hint:
			ult_key_hint.visible = false
			
		if ult_icon and ult_icon.has_method("set_icon_color"):
			ult_icon.set_icon_color(ICON_IDLE)   
# ---------------------------------------------------------------------------
# Gadget HUD
# ---------------------------------------------------------------------------

func _on_gadget_charge_changed(charge: int, max_charge: int) -> void:
	charge_bar.max_value = max_charge
	charge_bar.value = charge
	var full := charge >= max_charge
	if full and not _is_ready:
		_set_ready(true)
	elif not full and _is_ready:
		_set_ready(false)


func _set_ready(ready: bool) -> void:
	_is_ready = ready
	if _pulse_tween:
		_pulse_tween.kill()

	if ready:
		if _fill_style:
			_fill_style.bg_color = FILL_READY
		if gadget_icon.has_method("set_icon_color"):
			gadget_icon.set_icon_color(ICON_READY)
		key_hint.visible = true
		key_hint.modulate.a = 1.0
		_punch(gadget_widget, 1.2)
		_pulse_tween = create_tween().set_loops()
		if _frame_style:
			_pulse_tween.tween_property(_frame_style, "border_color", BORDER_READY_HI, 0.5).set_trans(Tween.TRANS_SINE)
		_pulse_tween.parallel().tween_property(key_hint, "modulate:a", 0.5, 0.5)
		if _frame_style:
			_pulse_tween.tween_property(_frame_style, "border_color", BORDER_READY, 0.5).set_trans(Tween.TRANS_SINE)
		_pulse_tween.parallel().tween_property(key_hint, "modulate:a", 1.0, 0.5)
	else:
		if _fill_style:
			_fill_style.bg_color = FILL_CHARGING
		if _frame_style:
			_frame_style.border_color = BORDER_IDLE
		key_hint.visible = false
		die_badge.visible = false
		if _current_name == "Dice":
			if gadget_icon.has_method("set_gadget"):
				gadget_icon.set_gadget(2)
			name_label.text = "Dice"
		if gadget_icon.has_method("set_icon_color"):
			gadget_icon.set_icon_color(ICON_IDLE)


func _apply_gadget(gadget_name: String) -> void:
	_current_name = gadget_name
	var idx: int = GADGET_ORDER.get(gadget_name, 0)
	if gadget_name == "Dice" and _dice_result_name != "":
		die_badge.visible = true
		if gadget_icon.has_method("set_gadget"):
			gadget_icon.set_gadget(DICE_ICON.get(_dice_result_name, 2))
		if gadget_icon.has_method("set_icon_color"):
			gadget_icon.set_icon_color(_dice_color(_dice_result_name))
		name_label.text = "Dice: %s" % _dice_result_name
	else:
		die_badge.visible = false
		name_label.text = gadget_name
		if gadget_icon.has_method("set_gadget"):
			gadget_icon.set_gadget(idx)
		if gadget_icon.has_method("set_icon_color"):
			gadget_icon.set_icon_color(ICON_READY if _is_ready else ICON_IDLE)
	_update_selector(idx)


func _update_selector(active_idx: int) -> void:
	for i in sel_icons.size():
		var ic: Control = sel_icons[i]
		var is_active: bool = i == active_idx
		ic.pivot_offset = ic.size / 2.0
		if ic.has_method("set_icon_color"):
			ic.set_icon_color(SEL_ACTIVE if is_active else SEL_INACTIVE)
		var t := create_tween()
		t.parallel().tween_property(ic, "scale", Vector2.ONE * (1.25 if is_active else 0.85), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(ic, "modulate:a", 1.0 if is_active else 0.5, 0.18)


func _on_gadget_selected(gadget_name: String) -> void:
	_apply_gadget(gadget_name)
	_punch(gadget_widget, 1.12)


func _on_dice_rolled(result_name: String) -> void:
	if _roll_tween:
		_roll_tween.kill()
	die_badge.visible = true
	gadget_icon.visible = false
	name_label.text = "Rolling..."
	_build_reel(result_name)
	reel.visible = true

	var item_h: float = reel.size.y
	var n: int = reel_strip.get_child_count()
	reel_strip.position.y = -(n - 1) * item_h
	_roll_tween = create_tween()
	_roll_tween.tween_property(reel_strip, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_roll_tween.tween_callback(_finish_dice_roll.bind(result_name))


func _build_reel(result_name: String) -> void:
	for child in reel_strip.get_children():
		child.queue_free()
	var item_h: float = reel.size.y
	var w: float = reel.size.x
	var n := 14
	for i in n:
		var entry: String = result_name if i == 0 else DICE_LABELS[randi() % DICE_LABELS.size()]
		var ic := GadgetIcon.new()
		ic.set_gadget(DICE_ICON.get(entry, 2))
		ic.set_icon_color(_dice_color(entry))
		ic.position = Vector2(0, i * item_h)
		ic.size = Vector2(w, item_h)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reel_strip.add_child(ic)


func _dice_color(entry: String) -> Color:
	match entry:
		"Jackpot":
			return Color(0.96, 0.74, 0.12)
		"Heal":
			return Color(0.3, 0.85, 0.4)
		"Snake Eyes":
			return Color(0.9, 0.3, 0.28)
		_:
			return Color(0.95, 0.96, 1.0)


func _finish_dice_roll(result_name: String) -> void:
	reel.visible = false
	gadget_icon.visible = true
	_dice_result_name = result_name
	if gadget_icon.has_method("set_gadget"):
		gadget_icon.set_gadget(DICE_ICON.get(result_name, 2))
	if gadget_icon.has_method("set_icon_color"):
		gadget_icon.set_icon_color(_dice_color(result_name))
	name_label.text = "Dice: %s" % result_name
	_punch(gadget_widget, 1.2)


func _on_gadget_use_denied() -> void:
	_shake(gadget_widget)
	if _frame_style and not _is_ready:
		if _flash_tween:
			_flash_tween.kill()
		_frame_style.border_color = BORDER_DENIED
		_flash_tween = create_tween()
		_flash_tween.tween_property(_frame_style, "border_color", BORDER_IDLE, 0.3)


func _on_gadget_used(gadget_name: String, voiceline: String) -> void:
	_dice_result_name = ""
	voiceline_label.text = "%s — \"%s\"" % [gadget_name, voiceline]
	voiceline_label.pivot_offset = voiceline_label.size / 2.0
	_punch(gadget_widget, 1.12)

	if _voiceline_tween:
		_voiceline_tween.kill()
	voiceline_label.modulate.a = 0.0
	voiceline_label.scale = Vector2(0.85, 0.85)
	voiceline_label.position.y = 30.0

	_voiceline_tween = create_tween()
	_voiceline_tween.parallel().tween_property(voiceline_label, "modulate:a", 1.0, 0.15)
	_voiceline_tween.parallel().tween_property(voiceline_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_voiceline_tween.parallel().tween_property(voiceline_label, "position:y", 40.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_voiceline_tween.tween_interval(1.8)
	_voiceline_tween.parallel().tween_property(voiceline_label, "modulate:a", 0.0, 0.4)
	_voiceline_tween.parallel().tween_property(voiceline_label, "position:y", 24.0, 0.4)


func _punch(node: Control, amount: float = 1.12) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(amount, amount)
	var t := create_tween()
	t.tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var t := create_tween()
	t.tween_property(node, "rotation", 0.10, 0.05)
	t.tween_property(node, "rotation", -0.10, 0.05)
	t.tween_property(node, "rotation", 0.06, 0.04)
	t.tween_property(node, "rotation", 0.0, 0.04)


func _on_take_damage_pressed() -> void:
	if _player:
		_player.take_damage(10)
