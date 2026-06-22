extends Sprite2D

func _physics_process(_delta):
	# Counteract the parent's rotation to keep sprite upright
	if get_parent() is RigidBody2D:
		rotation = -get_parent().rotation   
