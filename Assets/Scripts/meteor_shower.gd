extends Node2D

@export var shower_duration: float = 10.0

@export var min_spawn_delay: float = 0.2
@export var max_spawn_delay: float = 0.6

@export var min_time_between_showers: float = 3.0
@export var max_time_between_showers: float = 6.0

@export var x_variance: float = 100.0

@export var min_burst: int = 3
@export var max_burst: int = 5


var meteors: Array = []
var is_shower_active := false

# IMPORTANT: prevents overlapping loops
var loop_id := 0


func _ready():
	for node in find_children("*"):
		if node.has_method("start_fall"):
			meteors.append(node)
			_sleep(node)

	_schedule_next_shower()


# --------------------------------------------------
# SCHEDULING
# --------------------------------------------------
func _schedule_next_shower():
	var t = randf_range(min_time_between_showers, max_time_between_showers)
	get_tree().create_timer(t).timeout.connect(start_shower)


# --------------------------------------------------
# START SHOWER
# --------------------------------------------------
func start_shower():
	if is_shower_active:
		return

	is_shower_active = true

	loop_id += 1
	var current_id = loop_id

	get_tree().create_timer(shower_duration).timeout.connect(stop_shower)

	_fire_loop(current_id)


# --------------------------------------------------
# STOP SHOWER
# --------------------------------------------------
func stop_shower():
	if not is_shower_active:
		return

	is_shower_active = false

	# invalidate all running loops instantly
	loop_id += 1

	_schedule_next_shower()


# --------------------------------------------------
# FIRE LOOP (SAFE)
# --------------------------------------------------
func _fire_loop(id: int):
	if not is_shower_active:
		return

	# ignore old timers
	if id != loop_id:
		return

	var burst = randi_range(min_burst, max_burst)

	for i in burst:
		var m = _get_free_meteor()

		if m:
			var offset = randf_range(-x_variance, x_variance)

			m.spawn_position.x += offset
			m.start_fall()
			m.spawn_position.x -= offset

	var delay = randf_range(min_spawn_delay, max_spawn_delay)

	get_tree().create_timer(delay).timeout.connect(func():
		_fire_loop(id)
	)


# --------------------------------------------------
# METEOR POOL
# --------------------------------------------------
func _get_free_meteor():
	for m in meteors:
		if m.state == m.State.IDLE:
			return m
	return null


func _sleep(m):
	if m.has_method("_sleep"):
		m._sleep()
