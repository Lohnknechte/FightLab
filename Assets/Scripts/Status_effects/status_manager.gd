class_name StatusManager
extends Node

var active_effects: Array[ActiveEffect] = []

@onready var burn_sprite = $BurnSprite
@onready var poison_sprite = $PoisonSprite
@onready var shock_sprite = $ShockSprite

func _ready(): 
	burn_sprite.hide()
	poison_sprite.hide()
	shock_sprite.hide()

func _process(delta):
	for active in active_effects.duplicate():
		active.time_left -= delta

		active.effect.tick(get_parent(), delta, active)
		if active.time_left <= 0:
			remove_effect(active)
		


func apply_effect(effect: StatusEffect): 
	if get_parent()._is_dead:
		return
		
	for active in active_effects:
		if active.effect.id == effect.id:
			if active.stacks < effect.max_stacks:
				active.stacks += 1

			active.time_left = effect.duration
			return

	var active = ActiveEffect.new(effect)
	active_effects.append(active)

	effect.apply(get_parent())

	start_effect_visual(effect)


func remove_effect(active: ActiveEffect):
	active_effects.erase(active)

	active.effect.remove(get_parent())

	stop_effect_visual(active.effect)


func start_effect_visual(effect: StatusEffect):
	print("START VISUAL:", effect.id)
	match effect.id:
		"burn":
			burn_sprite.show()
			burn_sprite.z_index = 100
			burn_sprite.play("burn")

		"poison":
			poison_sprite.show()
			burn_sprite.z_index = 100
			poison_sprite.play("poison")

		"shock":
			shock_sprite.show()
			burn_sprite.z_index = 100
			shock_sprite.play("shock")


func stop_effect_visual(effect: StatusEffect):
	match effect.id:
		"burn":
			burn_sprite.hide()

		"poison":
			poison_sprite.hide()

		"shock":
			shock_sprite.hide()
			
func clear_effects():
	print("CLEARING EFFECTS")

	for active in active_effects.duplicate():
		remove_effect(active)

	active_effects.clear()
