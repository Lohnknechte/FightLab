extends Area2D

@export var speed: float = 200.0
@export var max_distance: float = 100.0
@export var rand_scale: float = 1.0
@export var bullet_damage: int = 10
var distance_traveled: float = 0.0
var previous_position: Vector2 
var effect: StatusEffect
var _has_hit: bool = false

func _ready() -> void:
	self.scale = Vector2(rand_scale,rand_scale)
	connect("body_entered", Callable(self, "_on_body_entered"))
	previous_position = global_position

func _physics_process(delta: float) -> void:
	# Move the bullet
	var move_vector = transform.x * speed * delta
	global_position += move_vector
	distance_traveled += move_vector.length()

	# Raycast along the bullet's path (Godot 4)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = previous_position
	query.to = global_position
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if _try_hit(collider):
			queue_free()
			return
		if collider is TileMap or collider is TileMapLayer:
			_has_hit = true
			queue_free()
			return

	previous_position = global_position

	# Despawn if exceeded max distance
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _try_hit(body):
		queue_free()


func _try_hit(body: Node) -> bool:
	if _has_hit or body == null:
		return false

	if body.is_in_group("Players"):
		_has_hit = true
		if body.has_method("take_damage"):
			body.take_damage(bullet_damage)
		if effect:
			var status_manager := body.get_node_or_null("StatusManager")
			if status_manager and status_manager.has_method("apply_effect"):
				status_manager.apply_effect(effect)
		return true

	if body.is_in_group("Destructibles"):
		_has_hit = true
		if body.has_method("detonate"):
			body.detonate()
		return true

	return false
