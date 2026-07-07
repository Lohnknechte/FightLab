class_name DiceGadget
extends Gadget

## Dice has its OWN pool of effects, weighted so strong outcomes are rarer.
## The outcome is rolled as soon as charge is full (or on re-selection while
## already charged) so the HUD can preview it before the player uses it.

const OUTCOMES: Array[String] = ["Heal", "Teleport", "Shockwave", "Swap", "Jackpot", "Snake Eyes"]
const WEIGHTS: Array[int] = [2, 3, 3, 4, 1, 6]
const VOICELINES: Dictionary = {
	"Heal": "Patched up!",
	"Teleport": "Now you see me...",
	"Shockwave": "Get baaack!",
	"Swap": "Let's trade places!",
	"Jackpot": "Surprise! You're Dead.",
	"Snake Eyes": "Ouch... bad luck.",
}

@export var shockwave_radius: float = 160.0
@export var shockwave_damage: int = 30
@export var shockwave_force: float = 650.0
@export var snake_eyes_damage: int = 25

signal rolled(result_name: String)

var _result: int = -1


func _init() -> void:
	gadget_name = "Dice"
	voiceline = "Surprise! You're Dead."


func on_charge_full() -> void:
	_roll()


func on_selected() -> void:
	_roll()


func _roll() -> void:
	if _result != -1:
		return
	_result = _weighted_pick()
	rolled.emit(OUTCOMES[_result])


func _weighted_pick() -> int:
	var total: int = 0
	for w in WEIGHTS:
		total += w
	var pick: int = randi() % total
	var acc: int = 0
	for i in WEIGHTS.size():
		acc += WEIGHTS[i]
		if pick < acc:
			return i
	return WEIGHTS.size() - 1


func _activate(character: Character) -> Dictionary:
	var idx: int = _result if _result != -1 else _weighted_pick()
	var outcome: String = OUTCOMES[idx]
	match idx:
		0:
			_heal(character)
		1:
			_teleport(character)
		2:
			_shockwave(character)
		3:
			_swap(character)
		4:
			_jackpot(character)
		5:
			_snake_eyes(character)
	_result = -1
	return {"name": "Dice \u2192 %s" % outcome, "voiceline": VOICELINES.get(outcome, voiceline)}


func _heal(character: Character) -> void:
	character.heal_to_full()
	character.spawn_vfx(character.global_position, Color(0.3, 0.85, 0.4), 44.0, 0.45)


func _teleport(character: Character) -> void:
	character.spawn_vfx(character.global_position, Color(0.6, 0.45, 0.95), 40.0, 0.35)
	character.teleport_to(character.get_global_mouse_position())
	character.spawn_vfx(character.global_position, Color(0.6, 0.45, 0.95), 40.0, 0.35)


func _shockwave(character: Character) -> void:
	character.spawn_vfx(character.global_position, Color(0.4, 0.85, 1.0), shockwave_radius, 0.4)
	for other in character.get_other_players():
		if character.global_position.distance_to(other.global_position) > shockwave_radius:
			continue
		var dir: Vector2 = (other.global_position - character.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		other.velocity = dir * shockwave_force + Vector2.UP * shockwave_force * 0.4
		if other.has_method("take_damage"):
			other.take_damage(shockwave_damage)


func _swap(character: Character) -> void:
	var others := character.get_other_players()
	if others.is_empty():
		return
	var target = others[randi() % others.size()]
	var tmp := character.global_position
	character.spawn_vfx(character.global_position, Color(0.95, 0.6, 0.2), 38.0, 0.35)
	character.global_position = target.global_position
	target.global_position = tmp
	character.spawn_vfx(character.global_position, Color(0.95, 0.6, 0.2), 38.0, 0.35)
	character.spawn_vfx(tmp, Color(0.95, 0.6, 0.2), 38.0, 0.35)


func _jackpot(character: Character) -> void:
	var others := character.get_other_players()
	if others.is_empty():
		return
	var victim = others[randi() % others.size()]
	character.spawn_vfx(victim.global_position, Color(0.95, 0.25, 0.22), 50.0, 0.45)
	victim.die()


func _snake_eyes(character: Character) -> void:
	character.spawn_vfx(character.global_position, Color(0.9, 0.3, 0.28), 34.0, 0.35)
	character.take_damage(snake_eyes_damage)
