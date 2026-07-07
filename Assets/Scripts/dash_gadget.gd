class_name DashGadget
extends Gadget

## Brief invulnerable horizontal burst that dodges shots. The actual
## movement override happens in Character._physics_process() since it needs
## to run every physics frame; this gadget only triggers it.


func _init() -> void:
	gadget_name = "Dash"
	voiceline = "Weeeeeeeeeeee"


func _activate(character: Character) -> Dictionary:
	character.start_dash()
	character.spawn_vfx(character.global_position, Color(0.85, 0.92, 1.0), 38.0, 0.3)
	return {}
