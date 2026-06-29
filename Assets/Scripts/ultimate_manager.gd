extends Node

signal charge_updated(current: float, max: float)

@export var ultimates: Array[Ultimate_Data]
@export var current_index: int = 0
var charge: float = 0.0
var has_cast: bool = false

func _process(delta: float) -> void:
	if has_cast:
		if charge > 0: 
			charge = 0
			emit_signal("charge_updated", 0, 100) # Force UI to empty
		return
	if ultimates.is_empty(): return
	
	var data = ultimates[current_index]
	
	# Safety: Ensure maxCharge is not 0 to prevent infinite loops or errors
	if data.maxCharge <= 0: return

	if charge < data.maxCharge:
		charge += data.charge_rate * delta
		if charge > data.maxCharge: 
			charge = data.maxCharge
		
		# Emit every frame while charging
		emit_signal("charge_updated", charge, data.maxCharge)

func cast_ultimate():
	print("1. Function Started") # Confirm entry
	
	if ultimates.is_empty():
		print("ERROR: Ultimates array is empty!")
		return
	
	var data = ultimates[current_index]
	print("2. Charge Check: ", charge, " vs Max: ", data.maxCharge)
	
	if charge < data.maxCharge:
		print("FAIL: Not enough charge! (Difference: ", data.maxCharge - charge, ")")
		return
	
	print("3. Spawning Scene...")
	
	var player = get_parent()
	var instance = data.scene.instantiate()
	get_tree().current_scene.add_child(instance)
	
	instance.global_position = player.global_position
	
	# You don't need to calculate direction here anymore! 
	# The 'activate' function in Avada_ulti.gd calculates it internally.
	# Just pass the player and damage.
	
	if instance.has_method("activate"):
		instance.activate(player, data.damage) # <--- Changed from initialize
	else:
		print("ERROR: Scene missing 'activate' function!")
	
	charge = 0
	emit_signal("charge_updated", 0, data.maxCharge)
	has_cast = true   

# Call this function when the round starts or player respawns
func reset_for_new_round():
	has_cast = false
	charge = 0
	emit_signal("charge_updated", 0, ultimates[current_index].maxCharge if not ultimates.is_empty() else 100)
