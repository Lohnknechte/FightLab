class_name Gadget
extends Node

## Base class for a chargeable player ability ("gadget"). A GadgetController
## calls activate() once its charge is full; subclasses override _activate()
## to perform the actual effect. This mirrors the BasicWeapon pattern used
## for weapons, so new gadgets can be added without touching Character or
## GadgetController.

var gadget_name: String = "Gadget"
var voiceline: String = "..."


## Override in subclasses to perform the gadget's effect. Return
## {"name": String, "voiceline": String} to report a custom outcome (e.g.
## Dice, whose text depends on the rolled result); an empty Dictionary falls
## back to gadget_name / voiceline.
func _activate(_character) -> Dictionary:
	return {}


func activate(character) -> Dictionary:
	var result := _activate(character)
	return {
		"name": result.get("name", gadget_name),
		"voiceline": result.get("voiceline", voiceline),
	}


## Override for gadgets that need to react once charge hits max (Dice rolls
## its outcome here so the HUD can show it before the player uses it).
func on_charge_full() -> void:
	pass


## Override for gadgets that need to react when re-selected while charged.
func on_selected() -> void:
	pass
