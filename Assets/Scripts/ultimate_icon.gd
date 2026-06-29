class_name UltimateChargeBar
extends Control

@export var current_charge: float = 0.0
@export var max_charge: float = 100.0
@export var fill_color: Color = Color(0.8, 0.031, 0.169, 0.753)
@export var ready_color: Color = Color(1.0, 1.0, 0.4)

func _draw() -> void:
	if max_charge <= 0: return
	
	var width: float = size.x
	var height: float = size.y
	
	# Calculate ratio (0.0 to 1.0)
	var ratio: float = clamp(current_charge / max_charge, 0.0, 1.0)
	
	# Calculate fill HEIGHT instead of width
	var fill_height: float = height * ratio
	
	# Determine color
	var current_color: Color = ready_color if ratio >= 1.0 else fill_color
	
	# 1. Draw Background (Full bar) 
	
	# 2. Draw Fill (Bottom-Up)
	if fill_height > 0:
		# Rect2(x, y, width, height)
		# We start drawing at (0, height - fill_height) to anchor it to the bottom
		var fill_rect: Rect2 = Rect2(0, height - fill_height, width, fill_height)
		draw_rect(fill_rect, current_color)
	
	# 3. Draw Border (Optional)
	draw_rect(Rect2(0, 0, width, height), Color(1, 1, 1, 0.3), false, 2.0)
	
	# 4. Ready Indicator (Top line instead of right line)
	if ratio >= 1.0:
		draw_rect(Rect2(0, 2.0, width, 2.0), Color(1, 1, 1, 0.8))
