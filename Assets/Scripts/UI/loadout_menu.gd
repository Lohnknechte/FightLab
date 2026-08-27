extends Control

signal confirmed
signal cancelled
signal profile_requested

const CATEGORY_TITLES := {
	&"weapon": "Weapon",
	&"ultimate": "Ultimate",
	&"gadget": "Gadget",
	&"effect": "Effect",
	&"armor": "Armor",
}

@onready var category_title: Label = $Center/Panel/Margin/Layout/Content/Options/OptionsInner/CategoryTitle
@onready var category_hint: Label = $Center/Panel/Margin/Layout/Content/Options/OptionsInner/CategoryHint
@onready var option_grid: Control = $Center/Panel/Margin/Layout/Content/Options/OptionsInner/OptionScroll/OptionGrid
@onready var status_label: Label = $Center/Panel/Margin/Layout/Footer/StatusLabel
@onready var weapon_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/Weapon
@onready var effect_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/EffectType
@onready var armor_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Armor
@onready var gadget_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Gadget
@onready var ultimate_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Ultimate

var _current_category: StringName = &"weapon"
var _draft_weapon_id := ""
var _draft_ultimate_id := ""
var _draft_gadget_id := ""
var _draft_effect_id := ""
var _draft_armor_id := ""


func _ready() -> void:
	weapon_button.pressed.connect(_show_category.bind(&"weapon"))
	effect_button.pressed.connect(_show_category.bind(&"effect"))
	armor_button.pressed.connect(_show_category.bind(&"armor"))
	gadget_button.pressed.connect(_show_category.bind(&"gadget"))
	ultimate_button.pressed.connect(_show_category.bind(&"ultimate"))
	$Center/Panel/Margin/Layout/Footer/Profile.pressed.connect(_open_profile)
	$Center/Panel/Margin/Layout/Footer/Cancel.pressed.connect(_cancel)
	$Center/Panel/Margin/Layout/Footer/Confirm.pressed.connect(_confirm)


func open() -> void:
	var state := get_node_or_null("/root/LoadoutState")
	if state == null:
		status_label.text = "Loadout state is unavailable."
		return

	_draft_weapon_id = state.selected_weapon_id
	_draft_ultimate_id = state.selected_ultimate_id
	_draft_gadget_id = state.selected_gadget_id
	_draft_effect_id = state.selected_effect_id
	_draft_armor_id = state.selected_armor_id
	status_label.text = "Changes are saved when you confirm."
	visible = true
	_show_category(&"weapon")
	weapon_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()


func _show_category(category: StringName) -> void:
	_current_category = category
	category_title.text = CATEGORY_TITLES.get(category, "Loadout")
	category_hint.text = "Choose your starting %s." % category_title.text.to_lower()
	_update_category_highlight()
	_rebuild_options()


func _update_category_highlight() -> void:
	weapon_button.modulate = Color(1.15, 1.08, 0.75) if _current_category == &"weapon" else Color.WHITE
	effect_button.modulate = Color(1.15, 1.08, 0.75) if _current_category == &"effect" else Color.WHITE
	armor_button.modulate = Color(1.15, 1.08, 0.75) if _current_category == &"armor" else Color.WHITE
	gadget_button.modulate = Color(1.15, 1.08, 0.75) if _current_category == &"gadget" else Color.WHITE
	ultimate_button.modulate = Color(1.15, 1.08, 0.75) if _current_category == &"ultimate" else Color.WHITE


func _rebuild_options() -> void:
	for child in option_grid.get_children():
		for conn in child.pressed.get_connections():
			child.pressed.disconnect(conn.callable)
		child.free()

	var state := get_node_or_null("/root/LoadoutState")
	if state == null:
		return

	var selected_id := _get_draft_id(_current_category)
	for option in state.get_options(_current_category):
		var button := Button.new()
		button.name = str(option.get("id", "Option")).capitalize().replace(" ", "")
		button.text = str(option.get("label", "Unknown"))
		button.tooltip_text = "Select %s" % button.text
		button.custom_minimum_size = Vector2(150, 148)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.toggle_mode = true
		button.button_pressed = option.get("id", "") == selected_id
		button.set_meta("option_id", str(option.get("id", "")))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_constant_override("icon_max_width", 72)
		button.add_theme_constant_override("h_separation", 0)
		var icon_path := str(option.get("icon", ""))
		if not icon_path.is_empty():
			var texture := load(icon_path)
			if is_instance_valid(texture):
				button.icon = texture
		button.pressed.connect(_select_option.bind(str(option.get("id", ""))))
		option_grid.add_child(button)


func _select_option(option_id: String) -> void:
	match _current_category:
		&"weapon":
			_draft_weapon_id = option_id
		&"ultimate":
			_draft_ultimate_id = option_id
		&"gadget":
			_draft_gadget_id = option_id
		&"effect":
			_draft_effect_id = option_id
		&"armor":
			_draft_armor_id = option_id
	for child in option_grid.get_children():
		child.button_pressed = child.get_meta("option_id", "") == option_id


func _get_draft_id(category: StringName) -> String:
	match category:
		&"weapon":
			return _draft_weapon_id
		&"ultimate":
			return _draft_ultimate_id
		&"gadget":
			return _draft_gadget_id
		&"effect":
			return _draft_effect_id
		&"armor":
			return _draft_armor_id
	return ""


func _confirm() -> void:
	var state := get_node_or_null("/root/LoadoutState")
	if state == null:
		status_label.text = "Loadout state is unavailable."
		return

	var error: Error = state.confirm_selection(_draft_weapon_id, _draft_ultimate_id, _draft_gadget_id, _draft_effect_id, _draft_armor_id)
	if error != OK:
		status_label.text = "Loadout could not be saved."
		return
	confirmed.emit()


func _cancel() -> void:
	cancelled.emit()


func _open_profile() -> void:
	visible = false
	profile_requested.emit()
