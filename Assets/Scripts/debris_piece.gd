class_name DebrisPiece
extends Node2D

## A single destructible-object shard. Falls with simple simulated gravity
## and frees itself after `lifetime` seconds. Movement runs in
## _physics_process() with the real frame delta instead of a fixed-step
## Timer, so it behaves correctly regardless of framerate.

const GRAVITY: float = 500.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.2

var _age: float = 0.0


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	global_position += velocity * delta

	_age += delta
	if _age >= lifetime:
		queue_free()
