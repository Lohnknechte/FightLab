extends Control # Attached to 'Ultimte' root

# Update this path to match your actual tree: Ultimte -> ChargeFill
@onready var charge_bar = $ChargeFill 
@onready var reel = $Reel # If you need to access the reel too

func _ready():
	var player = get_tree().get_first_node_in_group("Players")
	if player and player.has_node("UltimateManager"):
		var manager = player.get_node("UltimateManager")
		manager.charge_updated.connect(_on_manager_charge_updated)

func _on_manager_charge_updated(current: float, max: float):
	if charge_bar:
		charge_bar.current_charge = current
		charge_bar.max_charge = max
		charge_bar.queue_redraw()
		
		# Debug print to confirm data flow
		# print("Charge Updated: ", current, " / ", max)   
