extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/ShurikenBullet.tscn")
const THROW_STREAM = preload("res://audio/throw.mp3")

@onready var muzzle = $Muzzle
var _sprite: Sprite2D

# Der neue Statuseffekt deines Kollegen:
var attack_effect: StatusEffect
var cooldown_elapsed: float = 0.3

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
		# Hier wird die Schuss-Logik aufgerufen
		pass 


func shoot() -> void:
	can_shoot = false
	cooldown_elapsed = 0.0
	_emit_hud_state()

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	
	# Hier fließen beide Welten zusammen: Deine korrigierte Kleinschreibung + der Effekt des Kollegen!
	bullet.bullet_damage = bullet_damage
	bullet.rand_scale = bullet_rand_scale
	bullet.effect = attack_effect

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(THROW_STREAM, muzzle.global_position, -8.0, 0.98, 1.04)

	get_tree().root.add_child(bullet)

	await get_tree().create_timer(fire_cooldown).timeout
	can_shoot = true
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()