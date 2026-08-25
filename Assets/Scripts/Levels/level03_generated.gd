class_name GeneratedLevel
extends BaseLevel
## An arena whose geometry is produced by Wave Function Collapse at load time.
##
## The level owns no tiles of its own: [WFCLevelGenerator] paints the shared
## Tilemap scene, and this script turns the result into the things gameplay
## needs - spawn markers, character placement and a death zone that sits below
## whatever the solver came up with.

## Action that re-rolls the arena, ignored when the project has no such action.
const REGENERATE_ACTION := &"regenerate_level"

@export var generator_path: NodePath = ^"WFCGenerator"

## Tiles of clearance between the lowest arena tile and the death zone.
@export var death_zone_drop: float = 96.0

## Allows re-rolling the layout at runtime while play testing.
@export var allow_regenerate: bool = true

var _generator: WFCLevelGenerator


func _unhandled_input(event: InputEvent) -> void:
	# BaseLevel handles returning to the menu; skipping this would disable that
	# action in this level only.
	super._unhandled_input(event)
	if not allow_regenerate or not InputMap.has_action(REGENERATE_ACTION):
		return
	if event.is_action_pressed(REGENERATE_ACTION):
		regenerate()
		get_viewport().set_input_as_handled()


func _prepare_level() -> void:
	_generator = get_node_or_null(generator_path) as WFCLevelGenerator
	if _generator == null:
		push_error("GeneratedLevel: no WFCLevelGenerator at '%s'." % generator_path)
		return
	_build_arena()


## Re-rolls the arena and moves every character onto a fresh spawn point.
func regenerate(new_seed: int = -1) -> void:
	if _generator == null:
		return
	if not _generator.generate(new_seed):
		return
	_apply_generation()
	place_characters_on_spawn_points()


## The seed behind the current arena. Log it to reproduce a layout.
func get_layout_seed() -> int:
	return _generator.get_used_seed() if _generator != null else 0


func _build_arena() -> void:
	if not _generator.generate():
		return
	_apply_generation()
	# Characters are placed here rather than in _ready so they never spend a
	# frame inside freshly painted geometry.
	place_characters_on_spawn_points()


func _apply_generation() -> void:
	set_spawn_positions(_generator.get_spawn_positions())
	_move_death_zone_below(_generator.get_world_bounds())


func _move_death_zone_below(bounds: Rect2) -> void:
	var death_zone := get_node_or_null(death_zone_path) as Area2D
	if death_zone == null or bounds.size == Vector2.ZERO:
		return

	death_zone.global_position = Vector2(bounds.get_center().x, bounds.end.y + death_zone_drop)
	var shape_node := death_zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null:
		return
	# Reach well past the arena on both sides so nothing falls around the zone.
	rectangle.size = Vector2(bounds.size.x * 3.0, rectangle.size.y)
	shape_node.position = Vector2.ZERO
