extends GutTest
## Unit tests for wfc_bit_set.gd.
##
## The solver relies on the mutating helpers reporting whether they changed
## anything - that flag is what stops propagation from looping forever - so the
## return values matter as much as the resulting bits.

const BIT_COUNT := 70


func test_create_full_enables_every_bit() -> void:
	var bits := WFCBitSet.create_full(BIT_COUNT)

	assert_eq(WFCBitSet.count(bits), BIT_COUNT)
	for index in BIT_COUNT:
		assert_true(WFCBitSet.has(bits, index), "bit %d should be set" % index)


func test_create_empty_has_no_bits() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)

	assert_true(WFCBitSet.is_empty(bits))
	assert_eq(WFCBitSet.count(bits), 0)
	assert_eq(WFCBitSet.first(bits), -1)


func test_enable_reports_only_real_changes() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)

	assert_true(WFCBitSet.enable(bits, 33))
	assert_false(WFCBitSet.enable(bits, 33))
	assert_true(WFCBitSet.has(bits, 33))


func test_disable_reports_only_real_changes() -> void:
	var bits := WFCBitSet.create_full(BIT_COUNT)

	assert_true(WFCBitSet.disable(bits, 5))
	assert_false(WFCBitSet.disable(bits, 5))
	assert_false(WFCBitSet.has(bits, 5))


func test_bits_survive_word_boundaries() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)

	# Word 0 holds bits 0..30, so these straddle all three words.
	for index in [30, 31, 61, 69]:
		WFCBitSet.enable(bits, index)

	assert_eq(WFCBitSet.to_indices(bits), PackedInt32Array([30, 31, 61, 69]))


func test_intersect_keeps_shared_bits() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(bits, 1)
	WFCBitSet.enable(bits, 40)
	var mask := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(mask, 40)
	WFCBitSet.enable(mask, 41)

	assert_true(WFCBitSet.intersect(bits, mask))
	assert_eq(WFCBitSet.to_indices(bits), PackedInt32Array([40]))


func test_intersect_without_overlap_empties_the_set() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(bits, 2)
	var mask := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(mask, 3)

	assert_true(WFCBitSet.intersect(bits, mask))
	assert_true(WFCBitSet.is_empty(bits))


func test_intersect_reports_no_change_when_already_contained() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(bits, 7)

	assert_false(WFCBitSet.intersect(bits, WFCBitSet.create_full(BIT_COUNT)))
	assert_eq(WFCBitSet.to_indices(bits), PackedInt32Array([7]))


func test_unite_merges_bits() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(bits, 0)
	var other := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(other, 65)

	WFCBitSet.unite(bits, other)

	assert_eq(WFCBitSet.to_indices(bits), PackedInt32Array([0, 65]))


func test_first_returns_lowest_index() -> void:
	var bits := WFCBitSet.create_empty(BIT_COUNT)
	WFCBitSet.enable(bits, 62)
	WFCBitSet.enable(bits, 12)

	assert_eq(WFCBitSet.first(bits), 12)
