class_name FreezeEffect
extends StatusEffect
 
func apply(target):
	print(target.name, "is frozen")
	target.speed_multiplier *= damage_per_tick
	target.has_effect = id


func remove(target):
	print(target.name, "is no longer frozen") 
	target.speed_multiplier /= damage_per_tick
	target.has_effect = "none"
