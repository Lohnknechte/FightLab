extends Control # Attached to BarContainer

@onready var health_bar: ProgressBar = $HealthBar
@onready var ghost_bar: ProgressBar = $GhostBar

# HealthModule.gd
func setup(player: CharacterBody2D) -> void:
	# 1. Connect the signal for future updates
	player.health_changed.connect(_on_health_changed)
	
	# 2. FORCE an update immediately so the bars start at the correct values
	_on_health_changed(player.current_health, player.max_health)

func _on_health_changed(current: int, max_val: int) -> void:
	# Update max values first!
	health_bar.max_value = max_val
	ghost_bar.max_value = max_val
	
	# Set the health bars
	health_bar.value = current
	
	# If this is the VERY FIRST frame, just snap the ghost bar to the current health
	# This prevents the "missing" ghost bar effect at spawn
	if ghost_bar.value == 0: 
		ghost_bar.value = current
	else:
		# Only animate if it's an actual change
		_animate_ghost_bar(current)

func _animate_ghost_bar(target_value: float) -> void:
	var t = create_tween()
	t.tween_interval(0.5) 
	t.tween_property(ghost_bar, "value", target_value, 0.3)
