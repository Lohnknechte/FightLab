extends Control

# Pfad zu deiner Ultimate-ProgressBar im HUD
@onready var charge_bar: ProgressBar = $Ultimate/ChargeFill 

var _was_ready: bool = false # Verhindert endloses Pulsieren

# Wird von außen aufgerufen – übergib hier einfach die Spieler-Node
func setup(player: CharacterBody2D) -> void:
	if not player:
		push_error("UltimateHUD: Der übergebene Spieler ist null!")
		return
		
	# Holt den UltimateManager direkt aus der Spieler-Szene
	var ultimate_manager = player.get_node_or_null("UltimateManager")
	
	if not ultimate_manager:
		push_error("UltimateHUD: 'UltimateManager'-Knoten wurde auf dem Spieler (" + player.name + ") nicht gefunden!")
		return
		
	print("UltimateHUD: Verbinde mit UltimateManager von " + player.name)
	
	# Signal verbinden
	if ultimate_manager.has_signal("charge_updated"):
		ultimate_manager.charge_updated.connect(_on_charge_updated)
	else:
		push_error("UltimateHUD: 'charge_updated'-Signal auf dem UltimateManager nicht gefunden!")
		return

	# Initialen Zustand direkt auslesen
	_initialize_values(ultimate_manager)


# Holt sich die Startwerte direkt aus dem Manager und seiner aktuellen Ultimate-Ressource
func _initialize_values(manager: Node) -> void:
	var current_charge = manager.get("charge")
	var max_charge = 100.0 # Standard-Fallback
	
	var ultimates = manager.get("ultimates")
	var current_index = manager.get("current_index")
	
	if ultimates != null and current_index != null and not ultimates.is_empty():
		var current_data = ultimates[current_index]
		if current_data and "maxCharge" in current_data:
			max_charge = current_data.maxCharge

	if current_charge != null:
		_on_charge_updated(current_charge, max_charge)


# Wird bei jedem Signal-Emit aufgerufen
func _on_charge_updated(current: float, max_val: float) -> void:
	if not charge_bar: 
		push_error("UltimateHUD: Charge-Bar-Knoten nicht gefunden! Check deinen Pfad.")
		return
	
	# Werte auf die ProgressBar anwenden
	charge_bar.max_value = max_val
	charge_bar.value = current
	
	var is_ready = (current >= max_val)
	
	# Pulsieren nur beim exakten Übergang zu "voll"
	if is_ready and not _was_ready:
		_play_ready_pulse()
		
	_update_ready_visuals(is_ready)
	_was_ready = is_ready


func _update_ready_visuals(is_ready: bool) -> void:
	charge_bar.modulate = Color.GREEN if is_ready else Color.WHITE


func _play_ready_pulse() -> void:
	var t = create_tween()
	charge_bar.scale = Vector2.ONE
	t.tween_property(charge_bar, "scale", Vector2(1.1, 1.1), 0.1)
	t.tween_property(charge_bar, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC)
