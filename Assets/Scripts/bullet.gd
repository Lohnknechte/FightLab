extends Area2D

@export var speed: float = 200.0
@export var max_distance: float = 100.0
@export var rand_scale: float = 1.0
@export var bullet_damage: int = 10
var distance_traveled: float = 0.0
var previous_position: Vector2 
var effect: StatusEffect

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
		if collider and collider.is_in_group("Destructibles"):
			if collider.has_method("detonate"):
				collider.detonate()
			queue_free()
			return

	previous_position = global_position

	# Despawn if exceeded max distance
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Players"):
		if body.has_method("take_damage"):
			body.take_damage(bullet_Damage)
		if effect:
			body.get_node("StatusManager").apply_effect(effect)
	if body.is_in_group("Destructibles"):
		if body.has_method("detonate"):
			body.detonate()
		queue_free()
