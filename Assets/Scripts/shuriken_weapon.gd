extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/ShurikenBullet.tscn")
const THROW_STREAM = preload("res://audio/throw.mp3")

# Der neue Statuseffekt deines Kollegen:
var attack_effect: StatusEffect

# Deine neue Setup-Funktion mit den Shuriken-Stats:
func _setup() -> void:
	fire_cooldown = 0.3
	magazine_size = 0 # Cooldown-only weapon, no magazine
	bullet_damage = 20
	bullet_speed = 950.0
	bullet_max_distance = 950.0
	bullet_rand_scale = 0.9
	weapon_label = "Shuriken"

func _ready() -> void:
	_sprite = $Sprite
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	$Sprite.flip_v = to_mouse.x < 0
	look_at(mouse_pos)


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and can_shoot:
			shoot()


func _fire() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	bullet.bullet_damage = bullet_damage
	bullet.rand_scale = bullet_rand_scale
	bullet.effect = attack_effect
	get_tree().root.add_child(bullet)


func _play_fire_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(THROW_STREAM, muzzle.global_position, -8.0, 0.98, 1.04)

	await get_tree().create_timer(fire_cooldown).timeout
	can_shoot = true
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()