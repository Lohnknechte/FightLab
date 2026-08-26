extends GutTest
## Unit tests for wfc_terrain_grid.gd.
##
## The grid is what gameplay reads back from a generated layout, so out of
## bounds lookups have to behave like empty space and standing room has to
## account for head room.

var _grid: WFCTerrainGrid


func before_each() -> void:
	_grid = WFCTerrainGrid.new(Vector2i(4, 3))


func test_new_grid_is_empty() -> void:
	assert_eq(_grid.size, Vector2i(4, 3))
	assert_eq(_grid.count_solid(), 0)
	assert_eq(_grid.to_text(), "....\n....\n....")


func test_symbols_round_trip() -> void:
	_grid.set_symbol(Vector2i(1, 2), "G")

	assert_eq(_grid.get_symbol(Vector2i(1, 2)), "G")
	assert_true(_grid.is_solid(Vector2i(1, 2)))
	assert_eq(_grid.count_solid(), 1)


func test_cells_outside_the_grid_read_as_empty() -> void:
	assert_false(_grid.has_cell(Vector2i(-1, 0)))
	assert_eq(_grid.get_symbol(Vector2i(-1, 0)), ".")
	assert_false(_grid.is_solid(Vector2i(9, 9)))


func test_writes_outside_the_grid_are_ignored() -> void:
	_grid.set_symbol(Vector2i(4, 0), "D")

	assert_eq(_grid.count_solid(), 0)


func test_standable_requires_solid_ground_and_head_room() -> void:
	_grid.set_symbol(Vector2i(0, 2), "G")

	assert_true(_grid.is_standable(Vector2i(0, 2), 2))
	assert_false(_grid.is_standable(Vector2i(0, 1), 2), "empty cells are never standable")


func test_a_blocked_ceiling_removes_standing_room() -> void:
	_grid.set_symbol(Vector2i(0, 2), "G")
	_grid.set_symbol(Vector2i(0, 1), "D")

	assert_false(_grid.is_standable(Vector2i(0, 2), 2))


func test_find_standable_cells_lists_every_surface() -> void:
	_grid.set_symbol(Vector2i(0, 2), "G")
	_grid.set_symbol(Vector2i(3, 2), "G")

	assert_eq(_grid.find_standable_cells(2), [Vector2i(0, 2), Vector2i(3, 2)])
