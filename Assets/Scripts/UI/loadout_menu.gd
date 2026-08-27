extends Control

signal confirmed
signal cancelled
signal profile_requested


const CATEGORY_TITLES := {
	&"weapon": "Weapon",
	&"ultimate": "Ultimate",
	&"gadget": "Gadget",
	&"effect": "Effect",
	&"cosmetics": "Cosmetics",
}


const NORMAL_SKINS := [
	"Normal",
	"Catgirl",
	"Samurai",
	"Steampunk",
	"Wizard",
	"Birthday",
	"Christmas",
	"Easter",
	"Halloween"
]


const COMBINABLE_SKINS := [
	"Catgirl",
	"Samurai",
	"Steampunk",
	"Wizard"
]


@onready var category_title: Label = $Center/Panel/Margin/Layout/Content/Options/OptionsInner/CategoryTitle
@onready var category_hint: Label = $Center/Panel/Margin/Layout/Content/Options/OptionsInner/CategoryHint
@onready var option_grid: Control = $Center/Panel/Margin/Layout/Content/Options/OptionsInner/OptionScroll/OptionGrid
@onready var status_label: Label = $Center/Panel/Margin/Layout/Footer/StatusLabel

@onready var weapon_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/Weapon
@onready var effect_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/EffectType
@onready var cosmetics_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/Cosmetics

@onready var gadget_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Gadget
@onready var ultimate_button: Button = $Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Ultimate


@onready var preview_sprite: AnimatedSprite2D = $Center/Panel/Margin/Layout/HBoxContainer/CosmeticPreview/PreviewSprite

var _current_category: StringName = &"weapon"


var _draft_weapon_id := ""
var _draft_ultimate_id := ""
var _draft_gadget_id := ""
var _draft_effect_id := ""


var _draft_cosmetic_mode := "normal"
var _draft_gender := "Male"
var _draft_skin := "Normal"
var _draft_upper := ""
var _draft_lower := ""


func _ready() -> void:

	weapon_button.pressed.connect(_show_category.bind(&"weapon"))
	effect_button.pressed.connect(_show_category.bind(&"effect"))
	gadget_button.pressed.connect(_show_category.bind(&"gadget"))
	ultimate_button.pressed.connect(_show_category.bind(&"ultimate"))

	cosmetics_button.pressed.connect(_show_category.bind(&"cosmetics"))


	$Center/Panel/Margin/Layout/Footer/Profile.pressed.connect(_open_profile)
	$Center/Panel/Margin/Layout/Footer/Cancel.pressed.connect(_cancel)
	$Center/Panel/Margin/Layout/Footer/Confirm.pressed.connect(_confirm)



func open() -> void:

	var state := get_node_or_null("/root/LoadoutState")

	if state == null:
		status_label.text = "Loadout state unavailable."
		return


	_draft_weapon_id = state.selected_weapon_id
	_draft_ultimate_id = state.selected_ultimate_id
	_draft_gadget_id = state.selected_gadget_id
	_draft_effect_id = state.selected_effect_id


	_draft_cosmetic_mode = state.selected_cosmetic_mode
	_draft_gender = state.selected_gender
	_draft_skin = state.selected_skin
	_draft_upper = state.selected_upper_skin
	_draft_lower = state.selected_lower_skin


	visible = true

	_show_category(&"weapon")



func _unhandled_input(event: InputEvent) -> void:

	if visible and event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()



func _show_category(category: StringName) -> void:

	_current_category = category

	category_title.text = CATEGORY_TITLES.get(category, "Loadout")


	if category == &"cosmetics":
		category_hint.text = "Choose your appearance."
	else:
		category_hint.text = "Choose your starting %s." % category_title.text.to_lower()


	_update_category_highlight()

	_rebuild_options()



func _update_category_highlight() -> void:

	weapon_button.modulate = Color(1.15,1.08,0.75) if _current_category == &"weapon" else Color.WHITE
	effect_button.modulate = Color(1.15,1.08,0.75) if _current_category == &"effect" else Color.WHITE
	cosmetics_button.modulate = Color(1.15,1.08,0.75) if _current_category == &"cosmetics" else Color.WHITE

	gadget_button.modulate = Color(1.15,1.08,0.75) if _current_category == &"gadget" else Color.WHITE
	ultimate_button.modulate = Color(1.15,1.08,0.75) if _current_category == &"ultimate" else Color.WHITE



func _rebuild_options() -> void:

	for child in option_grid.get_children():
		child.queue_free()


	if _current_category == &"cosmetics":
		_build_cosmetic_menu()
		return


	var state := get_node_or_null("/root/LoadoutState")

	if state == null:
		return


	var selected_id := _get_draft_id(_current_category)


	for option in state.get_options(_current_category):

		var button := Button.new()

		button.text = str(option.get("label","Unknown"))

		button.custom_minimum_size = Vector2(150,148)

		button.toggle_mode = true

		button.button_pressed = option.get("id","") == selected_id

		button.set_meta("option_id",str(option.get("id","")))


		button.pressed.connect(
			_select_option.bind(str(option.get("id","")))
		)


		option_grid.add_child(button)
		
func _build_cosmetic_menu() -> void:

	var mode_button := Button.new()
	mode_button.text = "Mode: " + _draft_cosmetic_mode
	mode_button.custom_minimum_size = Vector2(200,50)
	mode_button.pressed.connect(_toggle_cosmetic_mode)
	option_grid.add_child(mode_button)


	var gender_button := Button.new()
	gender_button.text = "Gender: " + _draft_gender
	gender_button.custom_minimum_size = Vector2(200,50)
	gender_button.pressed.connect(_toggle_gender)
	option_grid.add_child(gender_button)


	if _draft_cosmetic_mode == "normal":

		for skin in NORMAL_SKINS:

			var button := Button.new()
			button.text = skin
			button.custom_minimum_size = Vector2(150,80)

			button.pressed.connect(
				_select_normal_skin.bind(skin)
			)

			option_grid.add_child(button)


	else:

		var upper_title := Label.new()
		upper_title.text = "Upper Skin"
		option_grid.add_child(upper_title)


		for skin in COMBINABLE_SKINS:

			var button := Button.new()
			button.text = "Upper: " + skin
			button.custom_minimum_size = Vector2(170,70)

			button.pressed.connect(
				_select_upper.bind(skin)
			)

			option_grid.add_child(button)



		var lower_title := Label.new()
		lower_title.text = "Lower Skin"
		option_grid.add_child(lower_title)


		for skin in COMBINABLE_SKINS:

			var button := Button.new()
			button.text = "Lower: " + skin
			button.custom_minimum_size = Vector2(170,70)

			button.pressed.connect(
				_select_lower.bind(skin)
			)

			option_grid.add_child(button)



	_update_preview()



func _toggle_cosmetic_mode() -> void:

	if _draft_cosmetic_mode == "normal":
		_draft_cosmetic_mode = "combined"
	else:
		_draft_cosmetic_mode = "normal"


	_update_preview()
	_rebuild_options()



func _toggle_gender() -> void:

	if _draft_gender == "Male":
		_draft_gender = "Female"
	else:
		_draft_gender = "Male"


	_update_preview()
	_rebuild_options()



func _select_normal_skin(skin:String) -> void:

	_draft_cosmetic_mode = "normal"
	_draft_skin = skin

	_draft_upper = ""
	_draft_lower = ""

	_update_preview()



func _select_upper(skin:String) -> void:

	_draft_upper = skin

	_update_preview()



func _select_lower(skin:String) -> void:

	_draft_lower = skin

	_update_preview()



func _update_preview() -> void:
	
	var path := ""

	if _draft_cosmetic_mode == "combined":
		var combined := _draft_upper + _draft_lower
		path = _get_combined_path(combined)
	else:
		path = _get_skin_path(_draft_skin)

	print("Preview path: ", path)

	var texture := load(path) as Texture2D
	if texture == null:
		print("Missing: ", path)
		return

	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.add_frame("idle", texture)

	frames.add_animation("walk")
	frames.add_frame("walk", texture)

	preview_sprite.sprite_frames = frames
	preview_sprite.play("idle")


func _get_skin_path(skin:String) -> String:

	var folder := ""


	match skin:

		"Normal":
			return "res://Assets/Sprites/Player/%s/Normal/Normal_%s_Idle.png" % [
				_draft_gender,
				_draft_gender
			]


		"Catgirl","Samurai","Steampunk","Wizard":
			folder = "Achievementskins"


		"Birthday","Christmas","Easter","Halloween":
			folder = "Eventskins"



	return "res://Assets/Sprites/Player/%s/%s/%s/%s_%s_Idle.png" % [
		_draft_gender,
		folder,
		skin,
		skin,
		_draft_gender
	]



func _get_combined_path(combined:String) -> String:

	return "res://Assets/Sprites/Player/%s/Combinedskins/%s/%s_%s_Idle.png" % [
		_draft_gender,
		combined,
		combined,
		_draft_gender
	]


func _select_option(option_id:String) -> void:

	match _current_category:

		&"weapon":
			_draft_weapon_id = option_id

		&"ultimate":
			_draft_ultimate_id = option_id

		&"gadget":
			_draft_gadget_id = option_id

		&"effect":
			_draft_effect_id = option_id



func _get_draft_id(category:StringName) -> String:

	match category:

		&"weapon":
			return _draft_weapon_id

		&"ultimate":
			return _draft_ultimate_id

		&"gadget":
			return _draft_gadget_id

		&"effect":
			return _draft_effect_id


	return ""



func _confirm() -> void:

	var state := get_node_or_null("/root/LoadoutState")

	if state == null:
		return


	state.set_cosmetics(
		_draft_cosmetic_mode,
		_draft_gender,
		_draft_skin,
		_draft_upper,
		_draft_lower
	)


	var error: Error = state.confirm_selection(
		_draft_weapon_id,
		_draft_ultimate_id,
		_draft_gadget_id,
		_draft_effect_id
	)


	if error != OK:

		status_label.text = "Loadout could not be saved."
		return


	confirmed.emit()



func _cancel() -> void:

	cancelled.emit()



func _open_profile() -> void:

	visible = false
	profile_requested.emit()
