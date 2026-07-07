class_name AirstrikeGadget
extends Gadget

## Drops a spread of bombs onto the mouse position (see airstrike_bomb.gd).

@export var bomb_count: int = 6
@export var spread: float = 150.0


func _init() -> void:
	gadget_name = "Airstrike"
	voiceline = "The Missile Knows where it is because it knows where it isn't"


func _activate(character: Character) -> Dictionary:
	_drop_bombs(character, character.get_global_mouse_position())
	return {}


func _drop_bombs(character: Character, center: Vector2) -> void:
	for i in range(bomb_count):
		var t: float = float(i) / float(max(1, bomb_count - 1))
		var x: float = center.x - spread * 0.5 + spread * t
		await character.get_tree().create_timer(0.08 * i).timeout
		if not character.is_inside_tree():
			return
		var bomb := AirstrikeBomb.new()
		bomb.target_y = center.y
		character.get_tree().current_scene.add_child(bomb)
		bomb.global_position = Vector2(x, center.y - 360.0)
