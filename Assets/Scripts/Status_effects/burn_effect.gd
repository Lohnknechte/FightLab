class_name BurnEffect
extends StatusEffect
 
func apply(target):
	print(target.name, "is burning")
	target.speed_multiplier *= 1.1

func tick(target, delta, active_effect):
	active_effect.tick_timer -= delta

	if active_effect.tick_timer <= 0:
		target.take_damage(damage_per_tick)
		active_effect.tick_timer = tick_rate

	spread(target)


func spread(target):
	var burn_area = target.get_node("BurnArea")

	for body in burn_area.get_overlapping_bodies():
		if body == target:
			continue

		if body.is_in_group("Players"):
			var status_manager = body.get_node("StatusManager")
			status_manager.apply_effect(self)
			
func remove(target):
	print(target.name, "is no longer burning")
	
	target.speed_multiplier *= 0.90909
