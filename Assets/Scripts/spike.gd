extends Area2D

@onready var damage_timer: Timer = $Timer
@export var damage: int = 10

var player_inside: Node2D = null

func _ready() -> void: 
	# Connect ALL signals safely via code so you don't rely on the editor UI
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	# Connect the timer to its timeout function safely
	if damage_timer and not damage_timer.timeout.is_connected(_on_timer_timeout):
		damage_timer.timeout.connect(_on_timer_timeout)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players"):
		player_inside = body
		
		if body.has_method("take_damage"):
			body.take_damage(damage) 
			
			# Safety check: only start if the timer actually exists
			if damage_timer:
				damage_timer.start()
		else:
			# Fallback: instantly reset the level if no damage method exists
			get_tree().reload_current_scene()


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null
		
		# Safety check: only stop if the timer actually exists
		if damage_timer:
			damage_timer.stop()


func _on_timer_timeout() -> void:
	# Make sure the player is still standing on the spike before dealing damage
	if player_inside and player_inside.has_method("take_damage"):
		player_inside.take_damage(damage)
