extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/SniperBullet.tscn")
const ROUND_FULL = preload("res://Assets/Sprites/weapons/ammo/sniper/sniper_round_full.png")
const ROUND_EMPTY = preload("res://Assets/Sprites/weapons/ammo/sniper/sniper_round_empty.png")
const SNIPER_SHOT_STREAM = preload("res://audio/108852__emsiarma__snipershot.wav")
const SNIPER_RELOAD_STREAM = preload("res://audio/276956__gfl7__awp-reload-sound.mp3")

# Der neue Statuseffekt deines Kollegen:
var attack_effect: StatusEffect

# Deine neue Setup-Funktion mit den Waffen-Stats:
func _setup() -> void:
	fire_cooldown = 0.75
	magazine_size = 3
	reload_time = 2.0
	bullet_damage = 50
	bullet_speed = 1350.0
	bullet_max_distance = 2200.0
	bullet_rand_scale = 1.0
	weapon_label = "Sniper"
	full_icon = ROUND_FULL
	empty_icon = ROUND_EMPTY
	
func _ready() -> void:
	_sprite = $Sprite
	current_ammo = magazine_size
	_emit_hud_state()


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	$Sprite.flip_v = to_mouse.x < 0
	look_at(mouse_pos)

	if is_reloading:
		reload_elapsed = min(reload_elapsed + delta, reload_time)
		_emit_hud_state()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and can_shoot and not is_reloading:
			shoot()
	elif event.is_action_pressed("reload_weapon"):
		reload()


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
		audio_manager.play_sfx_2d(SNIPER_SHOT_STREAM, muzzle.global_position, -5.0, 0.98, 1.02)


func _play_reload_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SNIPER_RELOAD_STREAM, muzzle.global_position, -7.0, 0.98, 1.02)