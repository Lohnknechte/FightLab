extends CanvasLayer

# Modules are now child nodes that hold their own logic
@onready var modules = {
	"health": $VBoxContainer/HBoxContainer/BarContainer,
	"weapon": $WeaponModule,
	"gadget": $GadgetModule,
	"ult": $UltModule
}

func initialize(player: CharacterBody2D) -> void:
	for key in modules:
		var module = modules[key]
		print("Checking module: ", key, " | Node: ", module)
		# 1. The safety check
		if module == null:
			push_error("HUD: Module '" + key + "' is null! Check your node path.")
			continue # Skip this module so the game doesn't crash
			
		# 2. Now it's safe to call has_method
		if module.has_method("setup"):
			module.setup(player)
		else:
			push_warning("HUD: Module '" + key + "' is missing a setup() function.")
