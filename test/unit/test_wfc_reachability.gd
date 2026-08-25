extends GutTest
## Unit tests for wfc_reachability.gd.
##
## Every case is a hand drawn arena small enough to reason about by eye. The
## point of the class is that reachability is directional - falling into a pit
## is easy and climbing out of it is not - so most of these check that a one way
## drop is not mistaken for a connection.

var _profile: WFCMovementProfile


func before_each() -> void:
	_profile = WFCMovementProfile.new()


func _analyse(text: String) -> WFCReachability:
	return WFCReachability.new(WFCTerrainGrid.from_text(text), _profile)


func test_a_gap_within_jump_range_stays_one_area() -> void:
	var reach := _analyse("""
		..........
		..........
		G..G......
	""")

	assert_eq(reach.get_components().size(), 1)
	assert_true(reach.has_edge(Vector2i(0, 2), Vector2i(3, 2)))


func test_a_gap_beyond_jump_range_splits_the_arena() -> void:
	var reach := _analyse("""
		..........
		..........
		G........G
	""")

	assert_eq(reach.get_components().size(), 2)
	assert_false(reach.are_mutually_reachable(Vector2i(0, 2), Vector2i(9, 2)))


func test_a_climbable_step_connects_both_levels() -> void:
	var reach := _analyse("""
		....G.
		......
		......
		GGGGGG
	""")

	assert_eq(reach.get_components().size(), 1, "three tiles up is climbable")
	assert_true(reach.are_mutually_reachable(Vector2i(3, 3), Vector2i(4, 0)))


func test_a_one_way_drop_is_not_a_connection() -> void:
	# The ledge is five tiles up: reachable going down, impossible coming back.
	var reach := _analyse("""
		..G.......
		..........
		..........
		..........
		..........
		GGGGGGGGGG
	""")

	assert_eq(reach.get_components().size(), 2)
	assert_true(reach.has_edge(Vector2i(2, 0), Vector2i(2, 5)), "you can always fall")
	assert_false(reach.has_edge(Vector2i(2, 5), Vector2i(2, 0)), "but not jump back up")
	assert_false(reach.are_mutually_reachable(Vector2i(2, 5), Vector2i(2, 0)))


func test_the_largest_component_is_the_floor_not_the_perch() -> void:
	var reach := _analyse("""
		..G.......
		..........
		..........
		..........
		..........
		GGGGGGGGGG
	""")

	var largest := reach.get_largest_component()
	assert_eq(largest.size(), 10)
	assert_false(largest.has(Vector2i(2, 0)), "the stranded perch is excluded")


func test_a_ceiling_blocks_the_take_off_below_it() -> void:
	var reach := _analyse("""
		......
		..D.G.
		......
		......
		GGGGGG
	""")

	assert_false(
		reach.has_edge(Vector2i(2, 4), Vector2i(4, 1)),
		"no room to jump with a slab overhead"
	)
	assert_true(
		reach.has_edge(Vector2i(3, 4), Vector2i(4, 1)),
		"one step across there is clear sky"
	)


func test_an_empty_arena_has_no_components() -> void:
	var reach := _analyse("""
		....
		....
	""")

	assert_eq(reach.get_cells().size(), 0)
	assert_eq(reach.get_components().size(), 0)
	assert_eq(reach.get_largest_component().size(), 0)


func test_components_are_ordered_largest_first() -> void:
	var reach := _analyse("""
		G.........GGGG
		..............
		..............
		..............
		..............
	""")

	var components := reach.get_components()
	assert_eq(components.size(), 2)
	assert_gt(components[0].size(), components[1].size())


func test_a_ledge_a_character_cannot_stand_on_is_not_a_node() -> void:
	# Only one empty tile above, so there is no room to stand.
	var reach := _analyse("""
		DDDD
		....
		GGGG
	""")

	for cell in reach.get_cells():
		assert_ne(cell, Vector2i(0, 2), "crawl space is not standing room")
