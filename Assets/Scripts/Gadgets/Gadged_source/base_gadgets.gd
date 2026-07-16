class_name BaseGadgets extends Node2D
 

func initialize(gadget_data: GadgetData) -> void:
	var data = gadget_data
	# Hier kannst du allgemeine Setup-Logik reinschreiben, die JEDES Gadget braucht

func activate(player: CharacterBody2D):
	assert(false, "Gadgets must override the 'activate' function!")
