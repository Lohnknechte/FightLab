extends Control 

# Ensure this path matches your scene tree exactly!
@onready var charge_bar: ProgressBar = $Frame/ChargeFill 

var _was_ready: bool = false # Tracks state to prevent infinite pulsing

func setup(player: CharacterBody2D) -> void:
	print("GadgetModule: Connecting to player...")
	player.gadget_charge_changed.connect(_on_charge_changed)
	player.gadget_selected.connect(_on_gadget_selected)
	
	# Initialize state
	_on_charge_changed(player.gadget_charge, player.gadget_max_charge)

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
	# Logic for when a gadget is chosen
	pass
