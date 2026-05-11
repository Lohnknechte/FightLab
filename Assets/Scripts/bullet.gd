extends Area2D

@export var speed: float = randf_range(150, 250) 
@export var max_distance: float = randf_range(75, 100) 
@export var rand_scale: float = randf_range(0.8, 1.4)
var distance_traveled: float = 0.0
var previous_position: Vector2

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
	if body.is_in_group("Destructibles"):
		if body.has_method("detonate"):
			body.detonate()
		queue_free()
