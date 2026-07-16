extends Node2D
## Test double for the parts of character.gd that status effects touch.
## Records calls so tests can assert on interactions instead of real combat state.

var speed_multiplier: float = 1.0
var can_move: bool = true
var has_effect: StringName = &"none"
var _is_dead: bool = false

var _weapons: Array[Node2D] = []
var _active_weapon: Node2D = null
var _shotgun: Node2D = null

var damage_calls: Array = []
var set_active_weapon_calls: Array = []


func take_damage(amount) -> void:
	damage_calls.append(amount)


func _set_active_weapon(weapon: Node2D) -> void:
	set_active_weapon_calls.append(weapon)
