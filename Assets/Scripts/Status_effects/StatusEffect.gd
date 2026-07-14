class_name StatusEffect
extends Resource

@export var id : StringName  
@export var duration : float
@export var max_stacks : int = 1
@export var tick_rate : float 
@export var damage_per_tick: float 

func apply(target): 
	pass

func tick(target, delta, active_effect):
	pass

func remove(target):
	pass
