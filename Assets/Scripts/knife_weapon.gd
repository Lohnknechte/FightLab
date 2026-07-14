extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/KnifeBullet.tscn")
const THROW_STREAM = preload("res://audio/throw.mp3")

@onready var muzzle = $Muzzle
var _sprite: Sprite2D

# Der neue Statuseffekt deines Kollegen:
var attack_effect: StatusEffect
var cooldown_elapsed: float = 0.85

# Deine neue Setup-Funktion mit den Messer-Stats:
func _setup() -> void:
	fire_cooldown = 0.85
	magazine_size = 0 # Cooldown-only weapon, no magazine
	bullet_damage = 34
	bullet_speed = 1050.0
	bullet_max_distance = 1200.0
	bullet_rand_scale = 1.0
	weapon_label = "Knife"

func _ready() -> void:
	_sprite = $Sprite
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	$Sprite.flip_v = to_mouse.x < 0
	look_at(mouse_pos)

	if not can_shoot:
		cooldown_elapsed = min(cooldown_elapsed + delta, fire_cooldown)
		_emit_hud_state()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and can_shoot:
			shoot()


func shoot() -> void:
	can_shoot = false
	cooldown_elapsed = 0.0
	_emit_hud_state()

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	
	# Hier fließen wieder beide Welten fehlerfrei zusammen:
	bullet.bullet_damage = bullet_damage
	bullet.rand_scale = bullet_rand_scale
	bullet.effect = attack_effect

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(THROW_STREAM, muzzle.global_position, -8.0, 0.98, 1.04)