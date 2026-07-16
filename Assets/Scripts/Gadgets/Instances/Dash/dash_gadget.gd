class_name DashGadget extends BaseGadgets

var dash_data: DashData

func initialize(gadget_data: GadgetData) -> void:
	# Rufe die Basis-Klasse auf
	super(gadget_data)
	print("dashGadget is da")
	# 2. Explizites Casting
	if gadget_data is DashData:
		dash_data = gadget_data
	else:
		push_error("DashGadget: Initialisierung fehlgeschlagen! Übergebenes GadgetData ist kein DashData.")
		
		
func activate(player: CharacterBody2D):
	print("DEBUG: activate() wurde aufgerufen mit Player: ", player)
	if not player:
		push_error("DashGadget: Spieler-Node nicht gefunden!")
		queue_free()
		return
	
	# 3. Sicherheitsprüfung vor dem Dash
	if dash_data == null:
		push_error("DashGadget: Dash wurde ohne Daten aktiviert! Abbruch.")
		queue_free()
		return
		
	print("DEBUG: Starte _perform_dash...")
	_perform_dash(player)

func _perform_dash(player: CharacterBody2D) -> void:
	player.is_dashing = true
	 
	var is_left = false
	if player.has_method("is_facing_left"):
		is_left = player.is_facing_left()
	else:
		# Fallback, falls die Funktion nicht existiert
		push_error("DashGadget: Player hat keine Funktion 'is_facing_left'!")
	
	var dir = -1.0 if is_left else 1.0
	var dash_velocity = dir * dash_data.dash_speed
   
	# Hier der "Sticky" Dash, der die Velocity erzwingt
	var timer = get_tree().create_timer(dash_data.dash_duration)
	while timer.time_left > 0:
		player.velocity.x = dash_velocity
		await get_tree().process_frame
		
	player.is_dashing = false
	player.velocity.x = 0
	queue_free()
