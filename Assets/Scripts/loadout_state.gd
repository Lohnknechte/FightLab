extends Node

signal selection_changed


const DEFAULT_WEAPON_ID := "shotgun"
const DEFAULT_ULTIMATE_ID := "avada"
const DEFAULT_GADGET_ID := "dash"
const DEFAULT_EFFECT_ID := "none"


# COSMETICS DEFAULTS
const DEFAULT_COSMETIC_MODE := "normal"
const DEFAULT_GENDER := "Male"
const DEFAULT_SKIN := "Normal"
const DEFAULT_UPPER_SKIN := ""
const DEFAULT_LOWER_SKIN := ""


const OPTIONS := {
	&"weapon": [
		{
			"id": "shotgun",
			"label": "Shotgun",
			"weapon_index": 0,
			"icon": "res://Assets/Sprites/weapons/guns/shotgun.png"
		},
		{
			"id": "sniper",
			"label": "Sniper",
			"weapon_index": 1,
			"icon": "res://Assets/Sprites/weapons/guns/sniper_old.png"
		},
		{
			"id": "shuriken",
			"label": "Shuriken",
			"weapon_index": 2,
			"icon": "res://Assets/Sprites/weapons/guns/shuriken.png"
		},
		{
			"id": "knife",
			"label": "Knife",
			"weapon_index": 3,
			"icon": "res://Assets/Sprites/weapons/guns/knife.png"
		},
	],

	&"ultimate": [
		{
			"id": "avada",
			"label": "Avada Kedavra",
			"manager_index": 0,
			"icon": ""
		},
	],

	&"gadget": [
		{
			"id": "dash",
			"label": "Dash",
			"manager_index": 0,
			"icon": ""
		},
	],

	&"effect": [
		{
			"id": "none",
			"label": "None",
			"resource_path": "",
			"icon": "res://Assets/Sprites/Effects/None.svg"
		},
		{
			"id": "burn",
			"label": "Fire",
			"resource_path": "res://Assets/Scripts/Status_effects/burn.tres",
			"icon": "res://Assets/Sprites/Effects/Fire.png"
		},
		{
			"id": "shock",
			"label": "Electric",
			"resource_path": "res://Assets/Scripts/Status_effects/shock.tres",
			"icon": "res://Assets/Sprites/Effects/Elec.png"
		},
		{
			"id": "freeze",
			"label": "Freeze",
			"resource_path": "res://Assets/Scripts/Status_effects/freeze.tres",
			"icon": "res://Assets/Sprites/Effects/Froze.png"
		},
		{
			"id": "poison",
			"label": "Poison",
			"resource_path": "res://Assets/Scripts/Status_effects/poison.tres",
			"icon": "res://Assets/Sprites/Effects/Poison.png"
		},
	],
}


var storage_path := "user://loadout.cfg"


# EXISTING LOADOUT
var selected_weapon_id := DEFAULT_WEAPON_ID
var selected_ultimate_id := DEFAULT_ULTIMATE_ID
var selected_gadget_id := DEFAULT_GADGET_ID
var selected_effect_id := DEFAULT_EFFECT_ID


# COSMETICS
var selected_cosmetic_mode := DEFAULT_COSMETIC_MODE
var selected_gender := DEFAULT_GENDER
var selected_skin := DEFAULT_SKIN
var selected_upper_skin := DEFAULT_UPPER_SKIN
var selected_lower_skin := DEFAULT_LOWER_SKIN



func _ready() -> void:
	load_selection()



func get_options(category: StringName) -> Array:
	return OPTIONS.get(category, []).duplicate(true)



func get_selected_id(category: StringName) -> String:

	match category:
		&"weapon":
			return selected_weapon_id
		&"ultimate":
			return selected_ultimate_id
		&"gadget":
			return selected_gadget_id
		&"effect":
			return selected_effect_id

	return ""



func get_selected_option(category: StringName) -> Dictionary:

	var selected_id := get_selected_id(category)

	for option in get_options(category):
		if option.get("id", "") == selected_id:
			return option

	return {}



func set_cosmetics(
	mode: String,
	gender: String,
	skin: String,
	upper: String,
	lower: String
) -> void:

	selected_cosmetic_mode = mode
	selected_gender = gender
	selected_skin = skin
	selected_upper_skin = upper
	selected_lower_skin = lower



func confirm_selection(
	weapon_id: String,
	ultimate_id: String,
	gadget_id: String,
	effect_id: String
) -> Error:

	if not _has_option(&"weapon", weapon_id):
		return ERR_INVALID_DATA

	if not _has_option(&"ultimate", ultimate_id):
		return ERR_INVALID_DATA

	if not _has_option(&"gadget", gadget_id):
		return ERR_INVALID_DATA

	if not _has_option(&"effect", effect_id):
		return ERR_INVALID_DATA


	selected_weapon_id = weapon_id
	selected_ultimate_id = ultimate_id
	selected_gadget_id = gadget_id
	selected_effect_id = effect_id


	var error := save_selection()

	if error == OK:
		selection_changed.emit()

	return error



func save_selection() -> Error:

	var config := ConfigFile.new()


	config.set_value(
		"loadout",
		"weapon",
		selected_weapon_id
	)

	config.set_value(
		"loadout",
		"ultimate",
		selected_ultimate_id
	)

	config.set_value(
		"loadout",
		"gadget",
		selected_gadget_id
	)

	config.set_value(
		"loadout",
		"effect",
		selected_effect_id
	)



	config.set_value(
		"cosmetics",
		"mode",
		selected_cosmetic_mode
	)

	config.set_value(
		"cosmetics",
		"gender",
		selected_gender
	)

	config.set_value(
		"cosmetics",
		"skin",
		selected_skin
	)

	config.set_value(
		"cosmetics",
		"upper",
		selected_upper_skin
	)

	config.set_value(
		"cosmetics",
		"lower",
		selected_lower_skin
	)



	return config.save(storage_path)



func load_selection() -> void:

	var config := ConfigFile.new()


	if config.load(storage_path) != OK:
		_reset_defaults()
		return



	selected_weapon_id = str(
		config.get_value(
			"loadout",
			"weapon",
			DEFAULT_WEAPON_ID
		)
	)

	selected_ultimate_id = str(
		config.get_value(
			"loadout",
			"ultimate",
			DEFAULT_ULTIMATE_ID
		)
	)

	selected_gadget_id = str(
		config.get_value(
			"loadout",
			"gadget",
			DEFAULT_GADGET_ID
		)
	)

	selected_effect_id = str(
		config.get_value(
			"loadout",
			"effect",
			DEFAULT_EFFECT_ID
		)
	)



	selected_cosmetic_mode = str(
		config.get_value(
			"cosmetics",
			"mode",
			DEFAULT_COSMETIC_MODE
		)
	)

	selected_gender = str(
		config.get_value(
			"cosmetics",
			"gender",
			DEFAULT_GENDER
		)
	)

	selected_skin = str(
		config.get_value(
			"cosmetics",
			"skin",
			DEFAULT_SKIN
		)
	)

	selected_upper_skin = str(
		config.get_value(
			"cosmetics",
			"upper",
			DEFAULT_UPPER_SKIN
		)
	)

	selected_lower_skin = str(
		config.get_value(
			"cosmetics",
			"lower",
			DEFAULT_LOWER_SKIN
		)
	)



	_sanitize_selection()



func _sanitize_selection() -> void:

	if not _has_option(&"weapon", selected_weapon_id):
		selected_weapon_id = DEFAULT_WEAPON_ID

	if not _has_option(&"ultimate", selected_ultimate_id):
		selected_ultimate_id = DEFAULT_ULTIMATE_ID

	if not _has_option(&"gadget", selected_gadget_id):
		selected_gadget_id = DEFAULT_GADGET_ID

	if not _has_option(&"effect", selected_effect_id):
		selected_effect_id = DEFAULT_EFFECT_ID


	if selected_gender != "Male" and selected_gender != "Female":
		selected_gender = DEFAULT_GENDER



func _has_option(category: StringName, option_id: String) -> bool:

	for option in get_options(category):

		if option.get("id", "") == option_id:
			return true

	return false



func _reset_defaults() -> void:

	selected_weapon_id = DEFAULT_WEAPON_ID
	selected_ultimate_id = DEFAULT_ULTIMATE_ID
	selected_gadget_id = DEFAULT_GADGET_ID
	selected_effect_id = DEFAULT_EFFECT_ID


	selected_cosmetic_mode = DEFAULT_COSMETIC_MODE
	selected_gender = DEFAULT_GENDER
	selected_skin = DEFAULT_SKIN
	selected_upper_skin = DEFAULT_UPPER_SKIN
	selected_lower_skin = DEFAULT_LOWER_SKIN
