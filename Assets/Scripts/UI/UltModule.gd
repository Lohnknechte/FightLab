extends Control # Attached to UltimateContainer

func setup(player: CharacterBody2D) -> void:
	player.ultimate_charge_updated.connect(_on_ult_updated)

func _on_ult_updated(current: float, max_val: float) -> void:
	# Update visuals (Pulse, colors, etc.)
	pass
