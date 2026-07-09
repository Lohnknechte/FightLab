extends AnimatedSprite2D

func _ready():	
	await(get_tree().create_timer(3))
	
	play("default")
