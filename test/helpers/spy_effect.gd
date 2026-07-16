extends StatusEffect
## Spy effect for StatusManager tests: records lifecycle calls, no side effects.

var apply_calls: int = 0
var tick_calls: int = 0
var remove_calls: int = 0
var last_tick_delta: float = 0.0
var last_target = null


func _init(effect_id: StringName = &"spy", effect_duration: float = 2.0,
		effect_max_stacks: int = 1, effect_tick_rate: float = 1.0,
		effect_damage_per_tick: float = 0.0) -> void:
	id = effect_id
	duration = effect_duration
	max_stacks = effect_max_stacks
	tick_rate = effect_tick_rate
	damage_per_tick = effect_damage_per_tick


func apply(target) -> void:
	apply_calls += 1
	last_target = target


func tick(target, delta, _active_effect) -> void:
	tick_calls += 1
	last_tick_delta = delta
	last_target = target


func remove(target) -> void:
	remove_calls += 1
	last_target = target
