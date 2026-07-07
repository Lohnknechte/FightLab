class_name ActiveEffect
extends RefCounted

var effect: StatusEffect

var time_left: float
var stacks: int = 1

var tick_timer: float = 1.0


func _init(status_effect: StatusEffect):
	effect = status_effect
	time_left = status_effect.duration
	tick_timer = status_effect.tick_rate
