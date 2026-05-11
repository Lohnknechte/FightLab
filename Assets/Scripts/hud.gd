extends CanvasLayer

@onready var health_bar: ProgressBar = $VBoxContainer/HBoxContainer/BarContainer/HealthBar
@onready var ghost_bar: ProgressBar = $VBoxContainer/HBoxContainer/BarContainer/GhostBar

var _player: CharacterBody2D
var _ghost_tween: Tween

func connect_to_player(player: CharacterBody2D) -> void:
	_player = player
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	ghost_bar.max_value = player.max_health
	ghost_bar.value = player.current_health
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health
	ghost_bar.max_value = max_health

	if _ghost_tween:
		_ghost_tween.kill()

	if new_health >= ghost_bar.value:
		ghost_bar.value = float(new_health)
		return

	_ghost_tween = create_tween()
	_ghost_tween.tween_interval(0.25)
	_ghost_tween.tween_property(ghost_bar, "value", float(new_health), 0.3)

func _on_take_damage_pressed() -> void:
	if _player:
		_player.take_damage(10)
