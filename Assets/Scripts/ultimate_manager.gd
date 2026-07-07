extends Node

signal charge_updated(current: float, max: float)

## The caster this manager casts ultimates for. Set explicitly (e.g. by the
## owning Character in _ready()) instead of relying on get_parent(), so this
## node isn't hard-coupled to a specific scene hierarchy.
@export var caster: Node2D

@export var ultimates: Array[UltimateData]
@export var current_index: int = 0
var charge: float = 0.0
var has_cast: bool = false


func _ready() -> void:
	if caster == null:
		caster = get_parent() as Node2D


func _process(delta: float) -> void:
	if has_cast:
		if charge > 0:
			charge = 0
			charge_updated.emit(0, 100) # Force UI to empty
		return
	if ultimates.is_empty():
		return

	var data := ultimates[current_index]

	# Safety: Ensure max_charge is not 0 to prevent infinite loops or errors
	if data.max_charge <= 0:
		return

	if charge < data.max_charge:
		charge += data.charge_rate * delta
		charge = min(charge, data.max_charge)
		charge_updated.emit(charge, data.max_charge)


func cast_ultimate() -> void:
	if ultimates.is_empty():
		push_warning("UltimateManager: ultimates array is empty!")
		return
	if caster == null:
		push_warning("UltimateManager: caster is not set!")
		return

	var data := ultimates[current_index]
	if charge < data.max_charge:
		return

	var instance := data.scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = caster.global_position

	if instance.has_method("activate"):
		instance.activate(caster, data.damage)
	else:
		push_error("UltimateManager: ultimate scene is missing an 'activate' function!")

	charge = 0
	charge_updated.emit(0, data.max_charge)
	has_cast = true


# Call this function when the round starts or player respawns
func reset_for_new_round() -> void:
	has_cast = false
	charge = 0
	charge_updated.emit(0, ultimates[current_index].max_charge if not ultimates.is_empty() else 100)
