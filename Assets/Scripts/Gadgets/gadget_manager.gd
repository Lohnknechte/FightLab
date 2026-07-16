extends Node

signal charge_updated(current: float, max: float) 
signal gadget_selected(gadget_name: String)

@export var gadgets: Array[GadgetData]
@export var current_index: int = 0
var charge: float = 0.0 
 

func _process(delta: float) -> void:
	if gadgets.is_empty(): return
	
	var data = gadgets[current_index] 
	
	# Safety: Ensure max_charge is not 0 to prevent infinite loops or errors
	if data.max_charge <= 0: return

	if charge < data.max_charge:
		charge += data.gadget_charge_rate * delta
		if charge > data.max_charge: 
			charge = data.max_charge
		
		# Emit every frame while charging
		emit_signal("charge_updated", charge, data.max_charge)

func cast_gadget():
	print("1. Function Started") # Confirm entry
	
	if gadgets.is_empty():
		print("ERROR: Gadget array is empty!")
		return
	
	
	var data = gadgets[current_index]
	print("2. Charge Check: ", charge, " vs Max: ", data.max_charge)
	
	if charge < data.max_charge:
		print("FAIL: Not enough charge! (Difference: ", data.max_charge - charge, ")")
		return
	
	print("3. Spawning Scene...")
	
	var player = get_parent() 
	var instance = data.visual_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	
	instance.global_position = player.global_position
	
	if instance.has_method("initialize"):
		instance.initialize(data) 
	else:
		print("WARNUNG: Szene hat kein 'initialize'!")
		
	if instance.has_method("activate"):
		instance.activate(player) # <--- Changed from initialize
	else:
		print("ERROR: Scene missing 'activate' function!")
	
	charge = 0
	emit_signal("charge_updated", 0, data.max_charge)

# Call this function when the round starts or player respawns
func reset_for_new_round():
	charge = 0
	emit_signal("charge_updated", 0, gadgets[current_index].max_charge if not gadgets.is_empty() else 100)
