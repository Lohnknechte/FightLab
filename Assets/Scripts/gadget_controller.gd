class_name GadgetController
extends Node

## Owns charge accumulation, selection and use of a character's gadgets.
## Add Gadget children to it (their order defines the selection cycle
## triggered by the "G" key). Extracted out of Character so gadget rules
## don't have to live inside the movement/weapon god-object.

signal gadget_charge_changed(charge: int, max_charge: int)
signal gadget_selected(gadget_name: String)
signal gadget_used(gadget_name: String, voiceline: String)
signal gadget_use_denied()
signal dice_rolled(result_name: String)

@export var max_charge: int = 100
@export var charge_rate: float = 8.0

var charge: int = 0
var current_index: int = 0

var _charge_accum: float = 0.0
var _character
var _gadgets: Array[Gadget] = []


func setup(character) -> void:
	_character = character
	_gadgets.clear()
	for child in get_children():
		if child is Gadget:
			_gadgets.append(child)
			if child.has_signal("rolled"):
				child.rolled.connect(dice_rolled.emit)

	gadget_charge_changed.emit(charge, max_charge)
	if not _gadgets.is_empty():
		gadget_selected.emit(_current_gadget().gadget_name)


func _process(delta: float) -> void:
	if _gadgets.is_empty() or charge >= max_charge:
		return

	_charge_accum += charge_rate * delta
	var new_charge: int = min(max_charge, int(_charge_accum))
	if new_charge == charge:
		return

	charge = new_charge
	gadget_charge_changed.emit(charge, max_charge)
	if charge >= max_charge:
		_current_gadget().on_charge_full()


func current_gadget_name() -> String:
	return _current_gadget().gadget_name if not _gadgets.is_empty() else ""


func select_next() -> void:
	if _gadgets.is_empty():
		return
	current_index = (current_index + 1) % _gadgets.size()
	gadget_selected.emit(_current_gadget().gadget_name)
	if charge >= max_charge:
		_current_gadget().on_selected()


func try_use() -> void:
	if _gadgets.is_empty() or charge < max_charge:
		gadget_use_denied.emit()
		return

	var result := _current_gadget().activate(_character)
	charge = 0
	_charge_accum = 0.0
	gadget_charge_changed.emit(charge, max_charge)
	gadget_used.emit(result.get("name", ""), result.get("voiceline", ""))


func _current_gadget() -> Gadget:
	return _gadgets[current_index]
