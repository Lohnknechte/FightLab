class_name WFCRuleFactory
extends RefCounted
## Builds small, hand checkable rule sets for the Wave Function Collapse tests.
##
## The shipped arena rules are tuned for looks; tests need alphabets where every
## legal layout can be reasoned about by hand.


static func chunk(
	id: String,
	pattern: String,
	weight: float = 1.0,
	flip: bool = false,
	row_min: int = -1,
	row_max: int = -1,
	tags: Array = []
) -> WFCChunk:
	var result := WFCChunk.new()
	result.id = StringName(id)
	result.pattern = pattern
	result.weight = weight
	result.allow_flip_h = flip
	result.row_min = row_min
	result.row_max = row_max
	result.tags = PackedStringArray(tags)
	return result


## A rule set whose two chunks both have empty edges, so every arrangement is
## legal. Useful wherever a test needs freedom rather than structure.
static func blocks() -> WFCRuleSet:
	var rules := WFCRuleSet.new()
	rules.chunk_size = 3
	rules.closed_borders = false
	rules.chunks = [
		chunk("empty", "...
...
..."),
		chunk("solid", "...
.D.
..."),
	]
	rules.compile()
	return rules


## A 3x3 alphabet with a floor that has to start and end with a cap. The top and
## bottom rows of every chunk are empty so a floor can actually sit between two
## rows of sky - with a closed border, a chunk whose edge is solid has nowhere to
## go at all.
static func ledges() -> WFCRuleSet:
	var rules := WFCRuleSet.new()
	rules.chunk_size = 3
	rules.closed_borders = true
	rules.chunks = [
		chunk("air", "...
...
...", 1.0),
		chunk("floor", "...
GGG
...", 1.0, false, 1, 1, ["ground"]),
		chunk("floor_end", "...
.GG
...", 1.0, true, 1, 1, ["ground"]),
	]
	rules.compile()
	return rules


## Index of the variant with the given id, or -1.
static func variant_of(rules: WFCRuleSet, id: String) -> int:
	for variant in rules.get_variant_count():
		if rules.get_variant_id(variant) == StringName(id):
			return variant
	return -1
