extends Node2D
## Stands in for the AnimatedSprite2D children StatusManager expects
## (FreezeSprite/BurnSprite/PoisonSprite/ShockSprite) without needing SpriteFrames.

var played: Array = []


func play(anim: StringName = &"") -> void:
	played.append(anim)
