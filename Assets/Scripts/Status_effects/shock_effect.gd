class_name ShockEffect
extends StatusEffect
 
func apply(target):
	print(target.name, "is paralized")
	target.can_move = false
	
	for weapon in target._weapons:
			weapon.set_process_input(false)


func remove(target):
	print(target.name, "is no longer paralized")  
	target.can_move = true  
	target._set_active_weapon(target._active_weapon if target._active_weapon != null else target._shotgun)
