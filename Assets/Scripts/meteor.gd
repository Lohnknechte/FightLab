extends Area2D

enum State {
	IDLE,
	FALLING,
	EXPLODING
}

@export var fall_speed: float = 400.0
@export var angle_variance: float = 0.5

@export var blast_radius: float = 100.0
@export var max_damage: float = 50.0
@export var blast_force: float = 300.0

@export_flags_2d_physics var wall_collision_layer: int = 1
@export var lifespan: float = 5.0

var state: State = State.IDLE

var parent_rigid: RigidBody2D
var spawn_position: Vector2
var lifespan_timer: SceneTreeTimer


func _ready():
	parent_rigid = get_parent()

	if not (parent_rigid is RigidBody2D):
		push_error("Meteor must be child of RigidBody2D")
		return

	spawn_position = parent_rigid.global_position
	_sleep()


func start_fall():
	if state != State.IDLE:
		return

	state = State.FALLING

	parent_rigid.global_position = spawn_position
	parent_rigid.linear_velocity = Vector2.ZERO
	parent_rigid.angular_velocity = 0.0

	parent_rigid.freeze = false
	parent_rigid.gravity_scale = 1.0

	parent_rigid.collision_layer = 1
	parent_rigid.collision_mask = wall_collision_layer
	parent_rigid.visible = true

	monitoring = true
	monitorable = true

	for c in parent_rigid.get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.disabled = false

		if c is Node2D:
			c.visible = true

	var angle = (PI / 2.0) + randf_range(-angle_variance, angle_variance)
	var speed = fall_speed * randf_range(0.85, 1.1)

	parent_rigid.linear_velocity = Vector2.from_angle(angle) * speed

	# lifespan timer
	if lifespan_timer:
		lifespan_timer.timeout.disconnect(_on_lifespan_timeout)

	lifespan_timer = get_tree().create_timer(lifespan)
	lifespan_timer.timeout.connect(_on_lifespan_timeout)


func _on_lifespan_timeout():
	if state == State.FALLING:
		_trigger_explosion()

 
func _on_body_entered(body):
	if state != State.FALLING:
		return

	if body == parent_rigid:
		return

	if body.is_in_group("Players") or body.is_in_group("Destructibles"):
		_trigger_explosion()
		return

	if body is TileMap or body is TileMapLayer:
		_trigger_explosion()


func _trigger_explosion():
	if state == State.EXPLODING:
		return

	state = State.EXPLODING

	var explosion_pos = global_position

	_spawn_vfx(explosion_pos, Color(0.668, 0.0, 0.131, 1.0), blast_radius, 0.4)

	# AREA2D OFF
	monitoring = false
	monitorable = false

	# RIGIDBODY OFF
	parent_rigid.freeze = true
	parent_rigid.gravity_scale = 0.0
	parent_rigid.linear_velocity = Vector2.ZERO
	parent_rigid.angular_velocity = 0.0

	parent_rigid.collision_layer = 0
	parent_rigid.collision_mask = 0
	parent_rigid.visible = false

	# shapes OFF
	for c in parent_rigid.get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.disabled = true

		if c is Node2D:
			c.visible = false

	await get_tree().physics_frame

	var space_state = get_world_2d().direct_space_state

	var players = get_tree().get_nodes_in_group("Players")
	var destructibles = get_tree().get_nodes_in_group("Destructibles")

	var ignore_list: Array[RID] = [self.get_rid(), parent_rigid.get_rid()]

	for p in players:
		if is_instance_valid(p):
			ignore_list.append(p.get_rid())

	for d in destructibles:
		if is_instance_valid(d):
			ignore_list.append(d.get_rid())

	# DAMAGE PLAYERS
	for player in players:
		if not is_instance_valid(player):
			continue

		var dist = explosion_pos.distance_to(player.global_position)
		if dist > blast_radius:
			continue

		var query = PhysicsRayQueryParameters2D.create(explosion_pos, player.global_position)
		query.collision_mask = wall_collision_layer
		query.exclude = ignore_list

		if space_state.intersect_ray(query).is_empty():
			var dmg = max_damage * (1.0 - dist / blast_radius)
			if player.has_method("take_damage"):
				player.take_damage(dmg)

	# DAMAGE DESTRUCTIBLES
	for obj in destructibles:
		if not is_instance_valid(obj):
			continue

		var dist = explosion_pos.distance_to(obj.global_position)
		if dist > blast_radius:
			continue

		var query = PhysicsRayQueryParameters2D.create(explosion_pos, obj.global_position)
		query.collision_mask = wall_collision_layer
		query.exclude = ignore_list

		if space_state.intersect_ray(query).is_empty():
			if obj.has_method("detonate"):
				obj.detonate()

	# return to pool
	get_tree().create_timer(3.0).timeout.connect(_sleep)


# --------------------------------------------------
# POOL RESET
# --------------------------------------------------
func _sleep():
	state = State.IDLE

	monitoring = false
	monitorable = false

	parent_rigid.freeze = true
	parent_rigid.gravity_scale = 0.0
	parent_rigid.linear_velocity = Vector2.ZERO
	parent_rigid.angular_velocity = 0.0

	parent_rigid.collision_layer = 0
	parent_rigid.collision_mask = 0
	parent_rigid.visible = false

	for c in parent_rigid.get_children():
		if c is Node2D:
			c.visible = false


# --------------------------------------------------
# VFX (WAS MISSING BEFORE)
# --------------------------------------------------
func _spawn_vfx(pos: Vector2, color: Color, radius: float, dur: float):
	var scene = get_tree().current_scene
	if scene == null:
		return

	var v = VfxBurst.new()
	v.setup(color, radius, dur)
	scene.add_child(v)
	v.global_position = pos
