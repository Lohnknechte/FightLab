extends AnimatedSprite2D

func _ready():	
	await(get_tree().create_timer(2))
	
	play("default")
