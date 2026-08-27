extends Node

signal selection_changed

const DEFAULT_WEAPON_ID := "shotgun"
const DEFAULT_ULTIMATE_ID := "avada"
const DEFAULT_GADGET_ID := "dash"
const DEFAULT_EFFECT_ID := "none"
const DEFAULT_ARMOR_ID := "nackabazi"

const OPTIONS := {
	&"weapon": [
		{"id": "shotgun", "label": "Shotgun", "weapon_index": 0, "icon": "res://Assets/Sprites/weapons/guns/shotgun.png"},
		{"id": "sniper", "label": "Sniper", "weapon_index": 1, "icon": "res://Assets/Sprites/weapons/guns/sniper_old.png"},
		{"id": "shuriken", "label": "Shuriken", "weapon_index": 2, "icon": "res://Assets/Sprites/weapons/guns/shuriken.png"},
		{"id": "knife", "label": "Knife", "weapon_index": 3, "icon": "res://Assets/Sprites/weapons/guns/knife.png"},
	],
	&"ultimate": [
		{"id": "avada", "label": "Avada Kedavra", "manager_index": 0, "icon": ""},
	],
	&"gadget": [
		{"id": "dash", "label": "Dash", "manager_index": 0, "icon": ""},
	],
	&"effect": [
		{"id": "none", "label": "None", "resource_path": "", "icon": "res://Assets/Sprites/Effects/None.svg"},
		{"id": "burn", "label": "Fire", "resource_path": "res://Assets/Scripts/Status_effects/burn.tres", "icon": "res://Assets/Sprites/Effects/Fire.png"},
		{"id": "shock", "label": "Electric", "resource_path": "res://Assets/Scripts/Status_effects/shock.tres", "icon": "res://Assets/Sprites/Effects/Elec.png"},
		{"id": "freeze", "label": "Freeze", "resource_path": "res://Assets/Scripts/Status_effects/freeze.tres", "icon": "res://Assets/Sprites/Effects/Froze.png"},
		{"id": "poison", "label": "Poison", "resource_path": "res://Assets/Scripts/Status_effects/poison.tres", "icon": "res://Assets/Sprites/Effects/Poison.png"},
	],
	&"armor": [
		{"id": "nackabazi", "label": "Nackabazi", "icon": "res://Assets/Sprites/ui/ruestung/nackabazi.png", "damage_reduction": 0.0, "speed_mult": 1.2, "jump_mult": 1.15, "max_health": 100},
		{"id": "lauch", "label": "Lauch", "icon": "res://Assets/Sprites/ui/ruestung/lauch.png", "damage_reduction": 0.05, "speed_mult": 1.0, "jump_mult": 1.0, "max_health": 150},
		{"id": "loser", "label": "Loser", "icon": "res://Assets/Sprites/ui/ruestung/loser.png", "damage_reduction": 0.10, "speed_mult": 0.8, "jump_mult": 0.85, "max_health": 200},
		{"id": "gehsteigpanzer", "label": "Gehsteigpanzer", "icon": "res://Assets/Sprites/ui/ruestung/gehsteigpanzer.png", "damage_reduction": 0.20, "speed_mult": 0.5, "jump_mult": 0.6, "max_health": 250},
	],
}

var storage_path := "user://loadout.cfg"
var selected_weapon_id := DEFAULT_WEAPON_ID
var selected_ultimate_id := DEFAULT_ULTIMATE_ID
var selected_gadget_id := DEFAULT_GADGET_ID
var selected_effect_id := DEFAULT_EFFECT_ID
var selected_armor_id := DEFAULT_ARMOR_ID


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
		&"armor":
			return selected_armor_id
	return ""


func get_selected_option(category: StringName) -> Dictionary:
	var selected_id := get_selected_id(category)
	for option in get_options(category):
		if option.get("id", "") == selected_id:
			return option
	return {}


func confirm_selection(weapon_id: String, ultimate_id: String, gadget_id: String, effect_id: String = DEFAULT_EFFECT_ID, armor_id: String = DEFAULT_ARMOR_ID) -> Error:
	if not _has_option(&"weapon", weapon_id):
		return ERR_INVALID_DATA
	if not _has_option(&"ultimate", ultimate_id):
		return ERR_INVALID_DATA
	if not _has_option(&"gadget", gadget_id):
		return ERR_INVALID_DATA
	if not _has_option(&"effect", effect_id):
		return ERR_INVALID_DATA
	if not _has_option(&"armor", armor_id):
		return ERR_INVALID_DATA

	selected_weapon_id = weapon_id
	selected_ultimate_id = ultimate_id
	selected_gadget_id = gadget_id
	selected_effect_id = effect_id
	selected_armor_id = armor_id
	var error := save_selection()
	if error == OK:
		selection_changed.emit()
	return error


func save_selection() -> Error:
	var config := ConfigFile.new()
	config.set_value("loadout", "weapon", selected_weapon_id)
	config.set_value("loadout", "ultimate", selected_ultimate_id)
	config.set_value("loadout", "gadget", selected_gadget_id)
	config.set_value("loadout", "effect", selected_effect_id)
	config.set_value("loadout", "armor", selected_armor_id)
	return config.save(storage_path)


func load_selection() -> void:
	var config := ConfigFile.new()
	if config.load(storage_path) != OK:
		_reset_defaults()
		return

	selected_weapon_id = str(config.get_value("loadout", "weapon", DEFAULT_WEAPON_ID))
	selected_ultimate_id = str(config.get_value("loadout", "ultimate", DEFAULT_ULTIMATE_ID))
	selected_gadget_id = str(config.get_value("loadout", "gadget", DEFAULT_GADGET_ID))
	selected_effect_id = str(config.get_value("loadout", "effect", DEFAULT_EFFECT_ID))
	selected_armor_id = str(config.get_value("loadout", "armor", DEFAULT_ARMOR_ID))
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
	if not _has_option(&"armor", selected_armor_id):
		selected_armor_id = DEFAULT_ARMOR_ID


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
	selected_armor_id = DEFAULT_ARMOR_ID
