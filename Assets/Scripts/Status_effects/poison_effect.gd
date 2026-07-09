class_name PoisonEffect
extends StatusEffect
 
func apply(target):
	print(target.name, "is poisoned")

func tick(target, delta, active_effect):
	active_effect.tick_timer -= delta
	if active_effect.tick_timer <= 0:
		target.take_damage(damage_per_tick*active_effect.stacks)
		active_effect.tick_timer = tick_rate
  
func remove(target):
	print(target.name, "is no longer poisoned")
