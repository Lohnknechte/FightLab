extends GutTest
## Unit tests for wfc_rule_set.gd.
##
## Compiling is where authored chunks turn into the variant list and adjacency
## table the solver consumes, including the mirrored copies.

const RuleFactory = preload("res://test/helpers/wfc_rule_factory.gd")


func test_compile_expands_flipped_chunks() -> void:
	var rules := RuleFactory.ledges()

	assert_eq(rules.get_variant_count(), 4)
	assert_true(rules.is_compiled())
	assert_ne(RuleFactory.variant_of(rules, "floor_end"), -1)
	assert_ne(RuleFactory.variant_of(rules, "floor_end_flipped"), -1)


func test_symmetric_chunks_are_not_duplicated() -> void:
	var rules := WFCRuleSet.new()
	rules.chunk_size = 2
	rules.chunks = [RuleFactory.chunk("air", "..\n..", 1.0, true)]

	assert_true(rules.compile())
	assert_eq(rules.get_variant_count(), 1)


func test_compile_rejects_a_wrongly_sized_chunk() -> void:
	var rules := WFCRuleSet.new()
	rules.chunk_size = 4
	rules.chunks = [RuleFactory.chunk("air", "..\n..")]

	assert_false(rules.compile())
	assert_false(rules.is_compiled())
	assert_push_error("is not a 4x4 square")


func test_adjacency_matches_facing_sockets() -> void:
	var rules := RuleFactory.ledges()
	var air := RuleFactory.variant_of(rules, "air")
	var floor_middle := RuleFactory.variant_of(rules, "floor")
	var floor_left := RuleFactory.variant_of(rules, "floor_end")

	var east_of_left_cap := rules.get_allowed(WFCChunk.Side.EAST, floor_left)
	assert_true(WFCBitSet.has(east_of_left_cap, floor_middle), "a cap continues into the floor")
	assert_false(WFCBitSet.has(east_of_left_cap, air), "a cap cannot open into thin air")

	var west_of_left_cap := rules.get_allowed(WFCChunk.Side.WEST, floor_left)
	assert_true(WFCBitSet.has(west_of_left_cap, air), "the closed side faces open space")


func test_border_mask_only_holds_chunks_with_an_empty_edge() -> void:
	var rules := RuleFactory.ledges()

	var west_border := rules.get_border_mask(WFCChunk.Side.WEST)
	assert_true(WFCBitSet.has(west_border, RuleFactory.variant_of(rules, "air")))
	assert_true(WFCBitSet.has(west_border, RuleFactory.variant_of(rules, "floor_end")))
	assert_false(WFCBitSet.has(west_border, RuleFactory.variant_of(rules, "floor")))


func test_row_mask_applies_the_authored_band() -> void:
	var rules := RuleFactory.ledges()
	var floor_middle := RuleFactory.variant_of(rules, "floor")

	assert_false(WFCBitSet.has(rules.get_row_mask(0), floor_middle))
	assert_true(WFCBitSet.has(rules.get_row_mask(1), floor_middle))


func test_tag_mask_selects_tagged_chunks_including_mirrors() -> void:
	var rules := RuleFactory.ledges()

	var ground := rules.get_tag_mask("ground")
	assert_eq(WFCBitSet.count(ground), 3)
	assert_false(WFCBitSet.has(ground, RuleFactory.variant_of(rules, "air")))


func test_stamp_expands_variants_into_terrain_cells() -> void:
	var rules := RuleFactory.ledges()
	var air := RuleFactory.variant_of(rules, "air")
	var floor_middle := RuleFactory.variant_of(rules, "floor")

	var grid := rules.stamp(PackedInt32Array([air, floor_middle]), Vector2i(2, 1))

	assert_eq(grid.size, Vector2i(6, 3))
	assert_eq(grid.to_text(), "......
...GGG
......")


func test_validate_accepts_a_sound_rule_set() -> void:
	var rules := RuleFactory.ledges()

	assert_eq(rules.validate(), PackedStringArray())


func test_validate_flags_a_chunk_nothing_can_sit_under() -> void:
	var rules := WFCRuleSet.new()
	rules.chunk_size = 3
	rules.closed_borders = true
	rules.chunks = [
		RuleFactory.chunk("air", "...
...
..."),
		# Its south edge is grass, no chunk offers a matching north edge and a
		# closed border will not take it either, so the solver can never place
		# it - the silent failure validate() exists to surface.
		RuleFactory.chunk("floating", "...
...
GGG"),
	]

	var problems := rules.validate()

	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "floating")


func test_validate_uses_caller_row_restrictions() -> void:
	var rules := RuleFactory.ledges()
	var floor_middle := RuleFactory.variant_of(rules, "floor")
	# Pin every row to air, which strands the floor chunks the same way a forced
	# ground row can strand a pillar in the real arena.
	var air_only := WFCBitSet.create_empty(rules.get_variant_count())
	WFCBitSet.enable(air_only, RuleFactory.variant_of(rules, "air"))
	var masks: Array[PackedInt32Array] = [air_only, air_only, air_only]

	var problems := rules.validate(masks)

	assert_gt(problems.size(), 0)
	assert_string_contains(str(problems), str(rules.get_variant_id(floor_middle)))
