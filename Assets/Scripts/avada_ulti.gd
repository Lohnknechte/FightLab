extends Node2D

# --- EXPORTED VARIABLES (Set these in the Inspector!) ---
@export var beam_color: Color = Color(0, 1, 0, 0.8) # Default Green
@export var beam_width: float = 5.0
@export var duration: float = 0.5

@onready var beam: Line2D = $BeamVisual
@onready var timer: Timer = $Timer

func activate(caster: Node, damage: int) -> void:
	# 1. Find Nearest Enemy
	var all_players = get_tree().get_nodes_in_group("Players")
	var nearest_target: Node2D = null
	var shortest_dist: float = INF

	for target in all_players:
		if not is_instance_valid(target) or target == caster: 
			continue
		var dist = caster.global_position.distance_to(target.global_position)
		if dist < shortest_dist:
			shortest_dist = dist
			nearest_target = target

	# 2. Configure Beam USING INSPECTOR VALUES
	if beam:
		if nearest_target:
			# Target Found: Beam connects to enemy
			global_position = caster.global_position
			var direction = (nearest_target.global_position - caster.global_position).normalized()
			rotation = direction.angle()
			
			# Apply Inspector Values
			beam.points = [Vector2.ZERO, Vector2(shortest_dist, 0)]
			beam.default_color = beam_color 
			beam.width = beam_width
			
			# Apply Damage
			if nearest_target.has_method("take_damage"):
				nearest_target.take_damage(damage)
		else:
			# No Target: Shoot forward
			global_position = caster.global_position
			var direction = caster.get_facing_direction() if caster.has_method("get_facing_direction") else Vector2.RIGHT
			rotation = direction.angle()
			
			# Apply Inspector Values (with fallback distance)
			beam.points = [Vector2.ZERO, Vector2(1000, 0)]
			beam.default_color = beam_color
			beam.width = beam_width

	# 3. Start Timer USING INSPECTOR DURATION
	if timer:
		timer.wait_time = duration # Override timer with Inspector value
		timer.start()

func _on_timer_timeout():
	queue_free()   
