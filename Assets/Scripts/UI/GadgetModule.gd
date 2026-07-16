extends Control 

# Ensure this path matches your scene tree exactly!
@onready var charge_bar: ProgressBar = $Frame/ChargeFill  
@onready var gadget_name_label: Label = $NameLabel

var _was_ready: bool = false # Tracks state to prevent infinite pulsing

func setup(player: CharacterBody2D) -> void:
	if not player:
		push_error("GadgetHUD: Der übergebene Spieler ist null!")
		return
		
	# Holt den UltimateManager direkt aus der Spieler-Szene
	var gadget_manager = player.get_node_or_null("GadgetManager")
	
	if not gadget_manager:
		push_error("GadgetHUD: 'GadgetManager'-Knoten wurde auf dem Spieler (" + player.name + ") nicht gefunden!")
		return
		
	print("GadgetHUD: Verbinde mit UltimateManager von " + player.name)
	
	# Signal verbinden
	if gadget_manager.has_signal("charge_updated"):
		gadget_manager.charge_updated.connect(_on_charge_changed)
	else:
		push_error("GadgetHUD: 'charge_updated'-Signal auf dem GadgetManager nicht gefunden!")
		return

	# Initialen Zustand direkt auslesen
	_initialize_values(gadget_manager)
	

func _initialize_values(manager: Node) -> void:
	var current_charge = manager.get("charge")
	var max_charge = 100.0 # Standard-Fallback
	
	var gadgets = manager.get("gadgets")
	var current_index = manager.get("current_index")
	
	if gadgets != null and current_index != null and not gadgets.is_empty():
		var current_data = gadgets[current_index]
		if current_data and "maxCharge" in current_data:
			max_charge = current_data.maxCharge
		if "gadget_name" in current_data:
			_on_gadget_selected(current_data.gadget_name)
		elif "name" in current_data: # Fallback, falls die Variable in der Resource nur "name" heißt
			_on_gadget_selected(current_data.name)
	if current_charge != null:
		_on_charge_changed(current_charge, max_charge)

	
func _on_charge_changed(current: int, max_val: int) -> void:
	if not charge_bar: 
		push_error("GadgetModule: Charge bar node not found! Check your path.")
		return
	
	charge_bar.max_value = max_val
	charge_bar.value = current
	
	var is_ready = (current >= max_val)
	
	# Only pulse if it JUST became ready
	if is_ready and not _was_ready:
		_play_ready_pulse()
		
	_update_ready_visuals(is_ready)
	_was_ready = is_ready # Update the state

func _update_ready_visuals(is_ready: bool) -> void:
	charge_bar.modulate = Color.GREEN if is_ready else Color.WHITE

func _play_ready_pulse() -> void:
	var t = create_tween()
	# Reset scale before pulsing
	charge_bar.scale = Vector2.ONE
	t.tween_property(charge_bar, "scale", Vector2(1.1, 1.1), 0.1)
	t.tween_property(charge_bar, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC)

func _on_gadget_selected(gadget_name: String) -> void:
	if gadget_name_label:
		gadget_name_label.text = gadget_name
