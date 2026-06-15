class_name VfxBurst
extends Node2D

## A short-lived, code-drawn burst: an expanding ring + inner flash that
## fades out and frees itself. Used for explosions, shockwaves, teleports, etc.

var color: Color = Color.WHITE
var max_radius: float = 40.0
var duration: float = 0.35
var _t: float = 0.0


func setup(c: Color, radius: float, dur: float = 0.35) -> void:
	color = c
	max_radius = radius
	duration = dur


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= duration:
		queue_free()


func _draw() -> void:
	var k: float = clampf(_t / duration, 0.0, 1.0)
	var r: float = lerpf(max_radius * 0.25, max_radius, k)
	var a: float = 1.0 - k
	var ring := Color(color.r, color.g, color.b, a)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, ring, maxf(2.0, 7.0 * (1.0 - k)), true)
	draw_circle(Vector2.ZERO, r * 0.35, Color(color.r, color.g, color.b, a * 0.35))
