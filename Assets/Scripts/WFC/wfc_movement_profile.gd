class_name WFCMovementProfile
extends Resource
## How far a character can travel in one jump, used to judge whether a generated
## arena is actually connected.
##
## The defaults mirror [code]character.gd[/code]: a 200 px/s run, a single
## 500 px/s jump off the floor and the project's 2D gravity. Because the numbers
## live here rather than in the solver, retuning the character and re-checking
## the levels is one edit.
##
## A jump that starts on one surface and lands [code]d[/code] pixels lower
## (negative when landing higher) is in the air for
## [code](v + sqrt(v^2 + 2*g*d)) / g[/code] seconds, and covers the run speed
## times that. Both the rise and the distance are scaled by
## [member safety_margin] so generated arenas never depend on a frame perfect
## jump.

@export var move_speed: float = 200.0

## Upward launch speed as a positive magnitude.
@export var jump_velocity: float = 500.0

@export var gravity: float = 980.0

@export var tile_size: int = 32

## Fraction of the theoretical maximum a jump may use. Lower means the generator
## demands more comfortable gaps.
@export_range(0.1, 1.0, 0.01) var safety_margin: float = 0.85

## Empty tiles a character needs above a surface to stand on it.
@export var head_room: int = 2


## Peak height of a jump in pixels, before the safety margin.
func get_peak_height() -> float:
	if gravity <= 0.0:
		return 0.0
	return (jump_velocity * jump_velocity) / (2.0 * gravity)


## Highest climb in whole tiles the generator will count on.
func get_max_rise_tiles() -> int:
	return int(floor(get_peak_height() * safety_margin / float(tile_size)))


## Seconds spent airborne when landing [param drop_pixels] below the take-off
## point. Negative values land higher up. Returns -1.0 when the jump cannot
## reach that height at all.
func get_air_time(drop_pixels: float) -> float:
	var discriminant := jump_velocity * jump_velocity + 2.0 * gravity * drop_pixels
	if discriminant < 0.0 or gravity <= 0.0:
		return -1.0
	return (jump_velocity + sqrt(discriminant)) / gravity


## Horizontal distance in pixels still available when landing
## [param drop_pixels] below the take-off point.
func get_reach(drop_pixels: float) -> float:
	var air_time := get_air_time(drop_pixels)
	if air_time < 0.0:
		return 0.0
	return move_speed * air_time * safety_margin


## Whether a single jump covers a step of [param delta] tiles, where a positive
## [code]y[/code] means the destination sits lower.
func can_traverse(delta: Vector2i) -> bool:
	if delta == Vector2i.ZERO:
		return false
	if -delta.y > get_max_rise_tiles():
		return false
	var drop_pixels := float(delta.y * tile_size)
	return absi(delta.x) * tile_size <= get_reach(drop_pixels)
