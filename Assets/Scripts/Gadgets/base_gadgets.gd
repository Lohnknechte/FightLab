class_name BaseGadets extends Node2D

@export var gadget_name: String = "Gadget"
@export var cooldown: float = 1.0

func activate():
	assert(false, "Gadgets must override the 'active' function!")
