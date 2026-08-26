extends GutTest
## Component tests for wfc_level_generator.gd against the shipped arena rules.
##
## These run the real solver, palette and Tilemap scene, so they catch content
## drift - a chunk that no longer tiles, or a palette symbol without a tile -
## that the pure unit tests cannot see.

const TILEMAP_SCENE := preload("res://src/scenes/Tilemap.tscn")
const RULES_PATH := "res://Assets/Scripts/WFC/RuleSets/arena_rule_set.tres"
const FIXED_SEED := 20250825

var _root: Node2D
var _layer: TileMapLayer
var _generator: WFCLevelGenerator


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)

	_layer = TILEMAP_SCENE.instantiate() as TileMapLayer
	_layer.name = "TileMapLayer"
	_root.add_child(_layer)

	_generator = WFCLevelGenerator.new()
	_generator.name = "WFCGenerator"
	_generator.rule_set = load(RULES_PATH)
	_generator.tile_map_layer_path = ^"../TileMapLayer"
	_generator.chunk_grid_size = Vector2i(9, 5)
	_generator.ground_row = 3
	_root.add_child(_generator)


func test_generation_paints_the_layer() -> void:
	watch_signals(_generator)

	assert_true(_generator.generate(FIXED_SEED))

	assert_signal_emitted_with_parameters(_generator, "generation_finished", [true])
	assert_gt(_layer.get_used_cells().size(), 0, "the arena should not be empty")


func test_every_painted_cell_exists_in_the_tile_set() -> void:
	assert_true(_generator.generate(FIXED_SEED))

	var tile_set := _layer.tile_set
	for cell in _layer.get_used_cells():
		var source_id := _layer.get_cell_source_id(cell)
		assert_true(tile_set.has_source(source_id), "unknown source %d at %s" % [source_id, cell])
		var source := tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			assert_true(
				source.has_tile(_layer.get_cell_atlas_coords(cell)),
				"missing atlas tile at %s" % cell
			)


func test_the_same_seed_rebuilds_the_same_arena() -> void:
	assert_true(_generator.generate(FIXED_SEED))
	var first := _generator.get_terrain_grid().to_text()

	assert_true(_generator.generate(FIXED_SEED))

	assert_eq(_generator.get_terrain_grid().to_text(), first)
	# The generator may re-roll past the requested seed chasing a connected
	# layout, but the search is deterministic so it lands on the same one.
	var settled_seed := _generator.get_used_seed()
	assert_true(_generator.generate(FIXED_SEED))
	assert_eq(_generator.get_used_seed(), settled_seed)


func test_regenerating_clears_the_previous_layout() -> void:
	assert_true(_generator.generate(FIXED_SEED))
	var cells_before := _layer.get_used_cells()

	assert_true(_generator.generate(FIXED_SEED + 1))
	assert_true(_generator.generate(FIXED_SEED))

	# Tiles left over from the middle layout would show up as extra cells here.
	assert_eq(_layer.get_used_cells(), cells_before)


func test_spawn_positions_sit_above_solid_ground() -> void:
	_generator.spawn_point_count = 4
	assert_true(_generator.generate(FIXED_SEED))

	var positions := _generator.get_spawn_positions()
	assert_eq(positions.size(), 4)
	for position in positions:
		var cell := _layer.local_to_map(_layer.to_local(position))
		assert_false(_generator.get_terrain_grid().is_solid(cell), "spawns stand in open space")
		assert_true(
			_generator.get_terrain_grid().is_solid(cell + Vector2i(0, 1)),
			"spawns need ground under them"
		)


func test_spawn_positions_are_spread_out() -> void:
	_generator.spawn_point_count = 4
	assert_true(_generator.generate(FIXED_SEED))

	var positions := _generator.get_spawn_positions()
	for index in positions.size():
		for other in range(index + 1, positions.size()):
			assert_gt(positions[index].distance_to(positions[other]), 32.0)


func test_world_bounds_cover_the_generated_arena() -> void:
	assert_true(_generator.generate(FIXED_SEED))

	var bounds := _generator.get_world_bounds()
	assert_eq(bounds.size, Vector2(9 * 4 * 32, 5 * 4 * 32))
	for position in _generator.get_spawn_positions():
		assert_true(bounds.has_point(position), "%s should sit inside %s" % [position, bounds])


func test_hazards_stay_clear_of_spawn_points() -> void:
	_generator.hazard_chance = 1.0
	_generator.hazard_spawn_clearance = 3
	assert_true(_generator.generate(FIXED_SEED))

	var spawn_cells: Array[Vector2i] = []
	for position in _generator.get_spawn_positions():
		spawn_cells.append(_layer.local_to_map(_layer.to_local(position)))

	for cell in _layer.get_used_cells():
		if _layer.get_cell_source_id(cell) != _generator.hazard_source_id:
			continue
		for spawn in spawn_cells:
			assert_gt(
				maxi(absi(spawn.x - cell.x), absi(spawn.y - cell.y)),
				2,
				"hazard at %s is too close to the spawn at %s" % [cell, spawn]
			)


func test_spawns_can_all_reach_each_other() -> void:
	_generator.spawn_point_count = 4
	assert_true(_generator.generate(FIXED_SEED))

	var reachability := _generator.get_reachability()
	assert_not_null(reachability)
	var cells: Array[Vector2i] = []
	for position in _generator.get_spawn_positions():
		cells.append(_layer.local_to_map(_layer.to_local(position)) + Vector2i(0, 1))

	for index in cells.size():
		for other in range(index + 1, cells.size()):
			assert_true(
				reachability.are_mutually_reachable(cells[index], cells[other]),
				"%s and %s are in different areas of the arena" % [cells[index], cells[other]]
			)


func test_the_shipped_rules_have_no_unplaceable_chunks() -> void:
	var masks: Array[PackedInt32Array] = []
	for row in _generator.chunk_grid_size.y:
		var mask := _generator.rule_set.get_row_mask(row)
		if row == _generator.ground_row:
			WFCBitSet.intersect(mask, _generator.rule_set.get_tag_mask(_generator.ground_tag))
		masks.append(mask)

	assert_eq(_generator.rule_set.validate(masks), PackedStringArray())
