extends Node2D

var _sprite: Sprite2D
const CHARACTER_SCENE = preload("res://src/scenes/player.tscn")

var originalPosX : float
var originalPosY : float

func _ready() -> void:
	_sprite = $Sprite  
	originalPosX = self.position.x
	originalPosY = self.position.y

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	$Sprite.flip_v = to_mouse.x < 0
	self.position.x = -originalPosX if CHARACTER_SCENE.facing_left else originalPosX
	
	look_at(mouse_pos)
