extends AnimatedSprite2D

func _ready():
	var delay = randf_range(0, 1)
	
	await(get_tree().create_timer(delay))
	
	play("default")
