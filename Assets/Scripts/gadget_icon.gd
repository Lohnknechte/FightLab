class_name GadgetIcon
extends Control

## Draws a simple, crisp gadget/outcome glyph entirely in code so it scales
## cleanly and needs no image assets.
## 0 Airstrike  1 Dash  2 Dice  3 Heal  4 Teleport  5 Shockwave
## 6 Swap  7 Jackpot  8 Snake Eyes

@export var gadget: int = 0
var icon_color: Color = Color(0.92, 0.94, 1.0)


func set_gadget(g: int) -> void:
	gadget = g
	queue_redraw()


func set_icon_color(c: Color) -> void:
	icon_color = c
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5)
	var u: float = min(size.x, size.y)
	match gadget:
		0:
			_draw_airstrike(c, u)
		1:
			_draw_dash(c, u)
		2:
			_draw_dice(c, u)
		3:
			_draw_heal(c, u)
		4:
			_draw_teleport(c, u)
		5:
			_draw_shockwave(c, u)
		6:
			_draw_swap(c, u)
		7:
			_draw_jackpot(c, u)
		8:
			_draw_snake_eyes(c, u)


func _draw_airstrike(c: Vector2, u: float) -> void:
	var w: float = u * 0.16
	var body := Vector2(c.x, c.y + u * 0.04)
	draw_circle(body, w, icon_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(body.x - w, body.y), Vector2(body.x + w, body.y),
		Vector2(body.x, body.y + u * 0.24)]), icon_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - w, c.y - u * 0.20), Vector2(c.x, c.y - u * 0.10),
		Vector2(c.x + w, c.y - u * 0.20), Vector2(c.x, c.y - u * 0.30)]), icon_color)
	var lw: float = max(2.0, u * 0.04)
	draw_line(Vector2(c.x - w * 2.4, c.y - u * 0.22), Vector2(c.x - w * 2.4, c.y - u * 0.02), icon_color, lw)
	draw_line(Vector2(c.x + w * 2.4, c.y - u * 0.22), Vector2(c.x + w * 2.4, c.y - u * 0.02), icon_color, lw)


func _draw_dash(c: Vector2, u: float) -> void:
	var hw: float = u * 0.16
	var hh: float = u * 0.22
	var th: float = max(3.0, u * 0.09)
	for off in [-hw * 0.9, hw * 0.5]:
		draw_polyline(PackedVector2Array([
			Vector2(c.x + off - hw * 0.5, c.y - hh),
			Vector2(c.x + off + hw * 0.5, c.y),
			Vector2(c.x + off - hw * 0.5, c.y + hh)]), icon_color, th)


func _draw_dice(c: Vector2, u: float) -> void:
	var d: float = u * 0.56
	draw_rect(Rect2(c.x - d * 0.5, c.y - d * 0.5, d, d), icon_color, false, max(3.0, d * 0.10))
	var pr: float = d * 0.10
	var o: float = d * 0.26
	for p in [Vector2(-o, -o), Vector2(o, -o), Vector2.ZERO, Vector2(-o, o), Vector2(o, o)]:
		draw_circle(c + p, pr, icon_color)


func _draw_heal(c: Vector2, u: float) -> void:
	var t: float = u * 0.14
	var l: float = u * 0.30
	draw_rect(Rect2(c.x - t, c.y - l, t * 2.0, l * 2.0), icon_color)
	draw_rect(Rect2(c.x - l, c.y - t, l * 2.0, t * 2.0), icon_color)


func _draw_teleport(c: Vector2, u: float) -> void:
	var w: float = max(2.0, u * 0.07)
	draw_arc(c, u * 0.30, deg_to_rad(40), deg_to_rad(320), 28, icon_color, w, true)
	draw_arc(c, u * 0.17, deg_to_rad(220), deg_to_rad(120), 24, icon_color, w, true)
	draw_circle(c, u * 0.05, icon_color)


func _draw_shockwave(c: Vector2, u: float) -> void:
	var w: float = max(2.0, u * 0.06)
	draw_arc(c, u * 0.14, 0.0, TAU, 24, icon_color, w, true)
	draw_arc(c, u * 0.26, 0.0, TAU, 28, icon_color, w, true)
	draw_arc(c, u * 0.38, 0.0, TAU, 32, icon_color, w, true)


func _draw_swap(c: Vector2, u: float) -> void:
	var w: float = max(3.0, u * 0.08)
	var y1: float = c.y - u * 0.15
	var y2: float = c.y + u * 0.15
	var xl: float = c.x - u * 0.28
	var xr: float = c.x + u * 0.28
	draw_line(Vector2(xl, y1), Vector2(xr, y1), icon_color, w)
	draw_polyline(PackedVector2Array([
		Vector2(xr - u * 0.12, y1 - u * 0.10), Vector2(xr, y1),
		Vector2(xr - u * 0.12, y1 + u * 0.10)]), icon_color, w)
	draw_line(Vector2(xr, y2), Vector2(xl, y2), icon_color, w)
	draw_polyline(PackedVector2Array([
		Vector2(xl + u * 0.12, y2 - u * 0.10), Vector2(xl, y2),
		Vector2(xl + u * 0.12, y2 + u * 0.10)]), icon_color, w)


func _draw_jackpot(c: Vector2, u: float) -> void:
	var pts := PackedVector2Array()
	var outer: float = u * 0.38
	var inner: float = u * 0.16
	for i in range(10):
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		var rad: float = outer if i % 2 == 0 else inner
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(pts, icon_color)


func _draw_snake_eyes(c: Vector2, u: float) -> void:
	var d: float = u * 0.52
	draw_rect(Rect2(c.x - d * 0.5, c.y - d * 0.5, d, d), icon_color, false, max(3.0, d * 0.10))
	var pr: float = d * 0.13
	draw_circle(c + Vector2(-d * 0.22, -d * 0.22), pr, icon_color)
	draw_circle(c + Vector2(d * 0.22, d * 0.22), pr, icon_color)
