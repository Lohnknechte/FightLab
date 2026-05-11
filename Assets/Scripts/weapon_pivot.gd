extends Node2D

var _sprite: Sprite2D
var _character: CharacterBody2D

var originalPosX : float
var originalPosY : float

func _ready() -> void:
	_sprite = $Sprite
	_character = get_parent()
	
	originalPosX = self.position.x
	originalPosY = self.position.y

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	$Sprite.flip_v = to_mouse.x < 0
	self.position.x = -originalPosX if _character.facing_left else originalPosX
	
	look_at(mouse_pos)
