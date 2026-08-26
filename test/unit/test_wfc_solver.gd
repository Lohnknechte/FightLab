extends GutTest
## Unit tests for wfc_solver.gd.
##
## The solver is deterministic for a given seed and must never emit a layout
## that breaks its own adjacency rules, so the checks here re-verify every seam
## of the solved grid rather than trusting a golden output.

const RuleFactory = preload("res://test/helpers/wfc_rule_factory.gd")


func test_solved_grid_is_fully_collapsed() -> void:
	var rules := RuleFactory.ledges()
	var solver := WFCSolver.new(rules, Vector2i(5, 2), 1)
	solver.apply_default_constraints()

	assert_true(solver.solve(), "the arena alphabet should always have a solution")
	var result := solver.get_result()
	assert_eq(result.size(), 10)
	for variant in result:
		assert_between(variant, 0, rules.get_variant_count() - 1)


func test_every_seam_respects_the_adjacency_table() -> void:
	var rules := RuleFactory.ledges()
	var size := Vector2i(6, 3)
	var solver := WFCSolver.new(rules, size, 7)
	solver.apply_default_constraints()
	assert_true(solver.solve())

	var result := solver.get_result()
	for y in size.y:
		for x in size.x:
			var variant := result[y * size.x + x]
			for direction in WFCRuleSet.DIRECTION_COUNT:
				var neighbour_cell: Vector2i = Vector2i(x, y) + WFCRuleSet.DIRECTIONS[direction]
				if neighbour_cell.x < 0 or neighbour_cell.y < 0:
					continue
				if neighbour_cell.x >= size.x or neighbour_cell.y >= size.y:
					continue
				var neighbour := result[neighbour_cell.y * size.x + neighbour_cell.x]
				assert_true(
					WFCBitSet.has(rules.get_allowed(direction, variant), neighbour),
					"cell %s and %s do not fit together" % [Vector2i(x, y), neighbour_cell]
				)


func test_same_seed_produces_the_same_layout() -> void:
	var rules := RuleFactory.ledges()

	var first := WFCSolver.new(rules, Vector2i(5, 3), 42)
	first.apply_default_constraints()
	assert_true(first.solve())

	var second := WFCSolver.new(rules, Vector2i(5, 3), 42)
	second.apply_default_constraints()
	assert_true(second.solve())

	assert_eq(first.get_result(), second.get_result())


func test_different_seeds_produce_different_layouts() -> void:
	var rules := RuleFactory.blocks()

	var first := WFCSolver.new(rules, Vector2i(8, 8), 1)
	assert_true(first.solve())
	var second := WFCSolver.new(rules, Vector2i(8, 8), 99)
	assert_true(second.solve())

	assert_ne(first.get_result(), second.get_result())


func test_closed_borders_keep_terrain_off_the_edge() -> void:
	var rules := RuleFactory.ledges()
	var size := Vector2i(4, 2)
	var solver := WFCSolver.new(rules, size, 3)
	solver.apply_default_constraints()
	assert_true(solver.solve())

	var grid := solver.build_terrain_grid()
	for y in grid.size.y:
		assert_false(grid.is_solid(Vector2i(0, y)), "left column must stay clear")
		assert_false(grid.is_solid(Vector2i(grid.size.x - 1, y)), "right column must stay clear")


func test_row_bands_keep_the_floor_out_of_the_sky() -> void:
	var rules := RuleFactory.ledges()
	var solver := WFCSolver.new(rules, Vector2i(4, 2), 5)
	solver.apply_default_constraints()
	assert_true(solver.solve())

	var grid := solver.build_terrain_grid()
	for x in grid.size.x:
		assert_false(grid.is_solid(Vector2i(x, 0)), "chunk row 0 is banned for floor chunks")


func test_restricting_a_cell_forces_that_variant() -> void:
	var rules := RuleFactory.blocks()
	var solid := RuleFactory.variant_of(rules, "solid")
	var mask := WFCBitSet.create_empty(rules.get_variant_count())
	WFCBitSet.enable(mask, solid)

	var solver := WFCSolver.new(rules, Vector2i(3, 3), 11)
	solver.restrict_cell(Vector2i(1, 1), mask)
	assert_true(solver.solve())

	assert_eq(solver.get_result()[4], solid)


func test_an_impossible_constraint_fails_instead_of_hanging() -> void:
	var rules := RuleFactory.ledges()
	var solver := WFCSolver.new(rules, Vector2i(3, 2), 1)
	solver.apply_default_constraints()
	# Row 0 is banned for every floor chunk, so demanding one there cannot work.
	solver.restrict_row(0, rules.get_tag_mask("ground"))

	assert_false(solver.solve(3))
	assert_eq(solver.get_attempts_used(), 3)
