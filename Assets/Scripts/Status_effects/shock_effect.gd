class_name ShockEffect
extends StatusEffect
 
func apply(target):
	print(target.name, "is paralized")
	target.can_move = false
	target.set_weapon_input_enabled(false)


func remove(target):
	print(target.name, "is no longer paralized")
	target.can_move = true
	target.set_weapon_input_enabled(true)
