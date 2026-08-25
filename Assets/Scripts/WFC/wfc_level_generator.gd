class_name WFCLevelGenerator
extends Node
## Drives a full Wave Function Collapse pass and paints the result into a
## [TileMapLayer].
##
## Everything the rest of the game needs afterwards - spawn positions and the
## world rect the arena occupies - is read back from the generated terrain, so a
## level scene never has to know how the layout was produced.

## Scene ids inside the tile set's scene collection source, matching Tilemap.tscn.
enum HazardScene { SPIKE = 1, CRATE = 2 }

## Emitted after every attempt, successful or not.
signal generation_finished(success: bool)

@export_group("Rules")
## Chunk alphabet and tile palette used for the layout.
@export var rule_set: WFCRuleSet
## Layer the arena is painted into. Defaults to a sibling named "TileMapLayer".
@export var tile_map_layer_path: NodePath = ^"../TileMapLayer"
## Layout size measured in chunks, not tiles.
@export var chunk_grid_size: Vector2i = Vector2i(9, 5)
## Top left tile of the painted arena.
@export var tile_origin: Vector2i = Vector2i.ZERO
## Seed for the layout, or 0 to pick a random one on every generation.
@export var generation_seed: int = 0

@export_group("Playability")
## Chunk-grid row forced to chunks tagged [member ground_tag], or -1 to let the
## solver decide where the main floor ends up.
@export var ground_row: int = -1
@export var ground_tag: String = "ground"
## Tiles of clear space a character needs above a cell to stand there.
@export var spawn_head_room: int = 2
## How many spawn markers the level asks for.
@export var spawn_point_count: int = 4
## A layout with fewer standing spots than this is rejected and re-rolled.
@export var min_standable_cells: int = 12
## Layout re-rolls before the generator gives up on the playability checks.
@export var max_layout_attempts: int = 12

@export_group("Reachability")
## Jump range used to decide which parts of the arena connect to each other.
## Left empty a profile matching character.gd is built on the first run.
@export var movement_profile: WFCMovementProfile
## Spawn points are only placed inside one mutually reachable area, and a layout
## whose largest such area is smaller than this is rejected and re-rolled.
@export var min_connected_cells: int = 24

@export_group("Hazards")
## Chance per eligible surface cell to receive a hazard from the scene source.
@export_range(0.0, 1.0, 0.01) var hazard_chance: float = 0.0
## Scene collection source id inside the tile set.
@export var hazard_source_id: int = 2
## Hazards keep at least this many tiles of distance from every spawn point.
@export var hazard_spawn_clearance: int = 3

var _terrain_grid: WFCTerrainGrid
var _reachability: WFCReachability
var _spawn_cells: Array[Vector2i] = []
var _used_seed: int = 0
var _rng := RandomNumberGenerator.new()


## Runs the solver and repaints the layer.
## Pass [param override_seed] to reproduce a specific layout.
func generate(override_seed: int = -1) -> bool:
	var layer := _resolve_layer()
	if layer == null or rule_set == null:
		push_error("WFCLevelGenerator: needs both a rule set and a tile map layer.")
		generation_finished.emit(false)
		return false
	if not rule_set.compile():
		generation_finished.emit(false)
		return false
	_report_rule_problems()

	var base_seed := override_seed
	if base_seed < 0:
		base_seed = generation_seed if generation_seed != 0 else randi()

	# Keep the roomiest layout seen so far. Re-rolling is how the generator
	# chases a well connected arena, but running out of attempts must never
	# leave the level empty, so the best of the batch is used instead.
	var best_grid: WFCTerrainGrid = null
	var best_reachability: WFCReachability = null
	var best_seed := 0
	var best_score := -1

	for attempt in maxi(max_layout_attempts, 1):
		var attempt_seed := base_seed + attempt * 7919
		var grid := _solve_layout(attempt_seed)
		if grid == null:
			continue
		if grid.find_standable_cells(spawn_head_room).size() < min_standable_cells:
			continue
		# Standing room is not enough on its own: a ledge nobody can jump to is
		# worse than no ledge at all, so spawns come from one connected area.
		var reachability := WFCReachability.new(grid, _get_movement_profile())
		var score := reachability.get_largest_component().size()
		if score > best_score:
			best_grid = grid
			best_reachability = reachability
			best_seed = attempt_seed
			best_score = score
		if score >= min_connected_cells:
			break

	if best_grid == null:
		push_error("WFCLevelGenerator: no usable layout after %d attempts." % max_layout_attempts)
		generation_finished.emit(false)
		return false
	if best_score < min_connected_cells:
		push_warning(
			"WFCLevelGenerator: best layout after %d attempts connects only %d cells (wanted %d)."
			% [max_layout_attempts, best_score, min_connected_cells]
		)

	_apply_layout(layer, best_grid, best_reachability, best_seed)
	generation_finished.emit(true)
	return true


## Commits a chosen layout: spawn points first, then tiles, then hazards.
func _apply_layout(
	layer: TileMapLayer,
	grid: WFCTerrainGrid,
	reachability: WFCReachability,
	layout_seed: int
) -> void:
	_used_seed = layout_seed
	_terrain_grid = grid
	_reachability = reachability
	_rng.seed = layout_seed
	_spawn_cells = _pick_spawn_cells(reachability.get_largest_component())
	WFCTerrainPainter.paint(layer, grid, rule_set.palette, tile_origin, _rng)
	_scatter_hazards(layer, grid.find_standable_cells(spawn_head_room))


## The generated terrain, or [code]null[/code] before the first successful run.
func get_terrain_grid() -> WFCTerrainGrid:
	return _terrain_grid


## Seed that produced the current layout, useful for reproducing a match.
func get_used_seed() -> int:
	return _used_seed


## Movement graph behind the current layout, or [code]null[/code] before the
## first successful run.
func get_reachability() -> WFCReachability:
	return _reachability


## Spawn positions in global space, one tile above the surface they sit on.
func get_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var layer := _resolve_layer()
	if layer == null:
		return positions
	for cell in _spawn_cells:
		var local := layer.map_to_local(tile_origin + cell + Vector2i(0, -1))
		positions.append(layer.to_global(local))
	return positions


## World rect covered by the arena, including the empty cells around it.
func get_world_bounds() -> Rect2:
	var layer := _resolve_layer()
	if layer == null or _terrain_grid == null:
		return Rect2()
	var top_left := layer.to_global(layer.map_to_local(tile_origin))
	var bottom_right := layer.to_global(layer.map_to_local(tile_origin + _terrain_grid.size))
	return Rect2(top_left, bottom_right - top_left)


## Falls back to the character's own movement numbers so the generator works
## without any wiring in the inspector.
func _get_movement_profile() -> WFCMovementProfile:
	if movement_profile == null:
		movement_profile = WFCMovementProfile.new()
		movement_profile.gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
		movement_profile.head_room = spawn_head_room
	return movement_profile


func _resolve_layer() -> TileMapLayer:
	if tile_map_layer_path.is_empty():
		return null
	return get_node_or_null(tile_map_layer_path) as TileMapLayer


## Warns once per generation about chunks the current settings make unplaceable,
## so a rule that silently stopped firing shows up in the output log.
func _report_rule_problems() -> void:
	for problem in rule_set.validate(_build_row_masks()):
		push_warning("WFCLevelGenerator: %s" % problem)


## The per-row restrictions this generator actually applies, so validation sees
## the same picture the solver does.
func _build_row_masks() -> Array[PackedInt32Array]:
	var masks: Array[PackedInt32Array] = []
	for row in chunk_grid_size.y:
		var mask := rule_set.get_row_mask(row)
		if row == ground_row:
			var ground_mask := rule_set.get_tag_mask(ground_tag)
			if not WFCBitSet.is_empty(ground_mask):
				WFCBitSet.intersect(mask, ground_mask)
		masks.append(mask)
	return masks


func _solve_layout(layout_seed: int) -> WFCTerrainGrid:
	var solver := WFCSolver.new(rule_set, chunk_grid_size, layout_seed)
	solver.apply_default_constraints()
	if ground_row >= 0 and ground_row < chunk_grid_size.y:
		var ground_mask := rule_set.get_tag_mask(ground_tag)
		if not WFCBitSet.is_empty(ground_mask):
			solver.restrict_row(ground_row, ground_mask)
	if not solver.solve():
		return null
	return solver.build_terrain_grid()


## Greedily spreads the spawn points so players never start on top of each other.
func _pick_spawn_cells(candidates: Array[Vector2i]) -> Array[Vector2i]:
	var chosen: Array[Vector2i] = []
	if candidates.is_empty():
		return chosen

	var remaining := candidates.duplicate()
	chosen.append(remaining.pop_at(_rng.randi() % remaining.size()))
	while chosen.size() < spawn_point_count and not remaining.is_empty():
		var best_index := 0
		var best_distance := -1.0
		for index in remaining.size():
			var nearest := INF
			for picked in chosen:
				nearest = minf(nearest, Vector2(remaining[index] - picked).length())
			if nearest > best_distance:
				best_distance = nearest
				best_index = index
		chosen.append(remaining.pop_at(best_index))
	return chosen


func _scatter_hazards(layer: TileMapLayer, standable: Array[Vector2i]) -> void:
	if hazard_chance <= 0.0:
		return
	for cell in standable:
		if _is_near_spawn(cell):
			continue
		if _rng.randf() >= hazard_chance:
			continue
		var scene_id := HazardScene.SPIKE if _rng.randf() < 0.5 else HazardScene.CRATE
		layer.set_cell(tile_origin + cell + Vector2i(0, -1), hazard_source_id, Vector2i.ZERO, scene_id)


func _is_near_spawn(cell: Vector2i) -> bool:
	for spawn in _spawn_cells:
		if absi(spawn.x - cell.x) <= hazard_spawn_clearance and absi(spawn.y - cell.y) <= hazard_spawn_clearance:
			return true
	return false
