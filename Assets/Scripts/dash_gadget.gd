class_name DashGadget
extends Gadget

## Brief invulnerable horizontal burst that dodges shots. The actual
## movement override happens in Character._physics_process() since it needs
## to run every physics frame; this gadget only triggers it and hands the
## tuning values (speed/duration) over to the character.

@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.18


func _init() -> void:
	gadget_name = "Dash"
	voiceline = "Weeeeeeeeeeee"


func _activate(character: Character) -> Dictionary:
	character.start_dash(dash_speed, dash_duration)
	character.spawn_vfx(character.global_position, Color(0.85, 0.92, 1.0), 38.0, 0.3)
	return {}
