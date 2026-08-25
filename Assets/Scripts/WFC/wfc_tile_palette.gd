class_name WFCTilePalette
extends Resource
## Maps the terrain symbols used in [WFCChunk] patterns onto real tile set cells.
##
## Keeping this in a resource means the same rule set can be repainted with a
## different tile sheet without touching the solver. Every dictionary is keyed by
## a single character symbol and holds the atlas coordinates inside
## [member source_id].

## Atlas source of the tile set that gets painted.
@export var source_id: int = 1

## Symbol -> tile used when the cell below is solid.
@export var body_tiles: Dictionary = {}

## Symbol -> tile used when the cell below is empty, so the carved underside of
## the sprite is visible. Falls back to [member body_tiles].
@export var underside_tiles: Dictionary = {}

## Symbol -> tile used where an exposed underside also ends horizontally. The
## sprites are drawn with the cut on their left, so right hand ends reuse the
## same tile flipped. Falls back to [member underside_tiles].
@export var end_tiles: Dictionary = {}

## Symbol -> second end variant, picked at random for visual variety.
@export var end_alt_tiles: Dictionary = {}


## Returns the atlas coordinates for [param symbol] or [code]Vector2i(-1, -1)[/code].
func get_body_tile(symbol: String) -> Vector2i:
	return body_tiles.get(symbol, Vector2i(-1, -1))


func has_symbol(symbol: String) -> bool:
	return body_tiles.has(symbol)


## Picks the tile for a cell whose underside is exposed.
## [param end_side] is -1 for a left hand end, 1 for a right hand end and 0 when
## the run continues on both sides.
func get_underside_tile(symbol: String, end_side: int, use_alt: bool) -> Vector2i:
	if end_side != 0:
		if use_alt and end_alt_tiles.has(symbol):
			return end_alt_tiles[symbol]
		if end_tiles.has(symbol):
			return end_tiles[symbol]
	if underside_tiles.has(symbol):
		return underside_tiles[symbol]
	return get_body_tile(symbol)
