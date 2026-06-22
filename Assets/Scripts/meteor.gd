extends Area2D

@export var fall_speed: float = 400.0
@export var angle_variance: float = 0.5
@export var blast_radius: float = 100.0
@export var max_damage: float = 50.0
@export var blast_force: float = 300.0
@export_flags_2d_physics var wall_collision_layer: int = 1
@export var respawn_time: float = 3.0 
@export var lifespan: float = 5.0

var has_exploded: bool = false
var parent_rigid: RigidBody2D
var spawn_position: Vector2
var lifespan_timer: SceneTreeTimer

func _ready():
	parent_rigid = get_parent()
	if not (parent_rigid is RigidBody2D):
		push_error("Meteor Area2D muss ein Kind von einem RigidBody2D sein!")
		return

	spawn_position = parent_rigid.global_position
	_start_fall()

func _start_fall():
	has_exploded = false
	
	parent_rigid.global_position = spawn_position
	parent_rigid.linear_velocity = Vector2.ZERO
	parent_rigid.angular_velocity = 0.0
	
	parent_rigid.freeze = false
	parent_rigid.gravity_scale = 1.0
	parent_rigid.collision_layer = 1 
	parent_rigid.collision_mask = wall_collision_layer 
	
	parent_rigid.visible = true
	for child in parent_rigid.get_children():
		if child is Node2D: child.visible = true
		
	var random_angle = (PI / 2.0) + randf_range(-angle_variance, angle_variance)
	parent_rigid.linear_velocity = Vector2.from_angle(random_angle) * fall_speed
	parent_rigid.angular_velocity = randf_range(-2.0, 2.0)

	set_deferred("monitoring", true)

	if lifespan_timer:
		lifespan_timer.timeout.disconnect(_on_lifespan_timeout)
	lifespan_timer = get_tree().create_timer(lifespan)
	lifespan_timer.timeout.connect(_on_lifespan_timeout)

func _on_lifespan_timeout():
	if not has_exploded:
		_trigger_explosion()

func _on_body_entered(body):
	if has_exploded: return
	if body == parent_rigid: return 

	if body.is_in_group("Players") or body.is_in_group("Destructibles"):
		_trigger_explosion()
		return

	if body is TileMap or body is TileMapLayer:
		_trigger_explosion()
		return

	if "collision_layer" in body:
		if (body.collision_layer & wall_collision_layer) > 0:
			_trigger_explosion()
			return

func _spawn_vfx(pos: Vector2, color: Color, radius: float, dur: float = 0.35) -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	var v := VfxBurst.new()
	v.setup(color, radius, dur)
	scene.add_child(v)
	v.global_position = pos

func _trigger_explosion():
	if has_exploded: return
	has_exploded = true
	
	var explosion_pos = global_position

	_spawn_vfx(explosion_pos, Color(0.668, 0.0, 0.131, 1.0), blast_radius, 0.4)

	monitoring = false 
	parent_rigid.freeze = true 
	parent_rigid.gravity_scale = 0.0
	parent_rigid.collision_layer = 0 
	parent_rigid.collision_mask = 0
	parent_rigid.visible = false 
	
	for child in parent_rigid.get_children():
		if child is Node2D: child.visible = false

	await get_tree().physics_frame

	var space_state = get_world_2d().direct_space_state

	var players = get_tree().get_nodes_in_group("Players")
	var destructibles = get_tree().get_nodes_in_group("Destructibles")

	# Erstellt eine Liste von RIDs aller Spieler und Destructibles, um sie im Strahl zu ignorieren
	var ignore_list: Array[RID] = [self.get_rid(), parent_rigid.get_rid()]
	for p in players:
		if is_instance_valid(p): ignore_list.append(p.get_rid())
	for d in destructibles:
		if is_instance_valid(d): ignore_list.append(d.get_rid())

	# Schaden an Spielern
	for player in players: 
		if not is_instance_valid(player): continue
		var target_pos = player.global_position
		if explosion_pos.distance_to(target_pos) > blast_radius: continue
		
		var query = PhysicsRayQueryParameters2D.create(explosion_pos, target_pos)
		query.collision_mask = wall_collision_layer
		query.exclude = ignore_list # Ignoriert alle Einheiten, trifft nur echte Wände/Tiles
		var result = space_state.intersect_ray(query)

		if result.is_empty():
			var distance = explosion_pos.distance_to(target_pos)
			var damage_multiplier = max(0.0, 1.0 - (distance / blast_radius))
			if player.has_method("take_damage"):
				player.take_damage(max_damage * damage_multiplier)

	# Schaden an Destructibles
	for obj in destructibles:
		if not is_instance_valid(obj): continue
		var target_pos = obj.global_position
		if explosion_pos.distance_to(target_pos) > blast_radius: continue
		
		var query = PhysicsRayQueryParameters2D.create(explosion_pos, target_pos)
		query.collision_mask = wall_collision_layer
		query.exclude = ignore_list # Ignoriert alle Einheiten, trifft nur echte Wände/Tiles
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			if obj.has_method("detonate"):
				obj.detonate()

	get_tree().create_timer(respawn_time).timeout.connect(_reset_meteor)

func _reset_meteor():
	_start_fall()
