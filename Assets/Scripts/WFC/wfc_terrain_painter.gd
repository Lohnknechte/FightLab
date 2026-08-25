class_name WFCTerrainPainter
extends RefCounted
## Draws a [WFCTerrainGrid] into a [TileMapLayer] using a [WFCTilePalette].
##
## The solver only decides which terrain sits in a cell; picking the sprite that
## fits the neighbourhood happens here. The Bloecke sheet carries a carved
## underside variant and a left hand end variant per terrain, so exposed edges
## get those instead of the plain body tile and right hand ends reuse the left
## hand sprite mirrored.

## Transform bit Godot stores in the alternative tile id to mirror a cell.
const FLIP_H := TileSetAtlasSource.TRANSFORM_FLIP_H


## The tile chosen for a single cell.
class TilePlacement extends RefCounted:
	var atlas_coords: Vector2i
	var alternative_tile: int

	func _init(coords: Vector2i, alternative: int = 0) -> void:
		atlas_coords = coords
		alternative_tile = alternative


## Clears [param layer] and repaints it from [param grid].
## [param origin] shifts the whole layout in tile map coordinates.
static func paint(
	layer: TileMapLayer,
	grid: WFCTerrainGrid,
	palette: WFCTilePalette,
	origin: Vector2i = Vector2i.ZERO,
	rng: RandomNumberGenerator = null
) -> void:
	if layer == null or grid == null or palette == null:
		push_error("WFCTerrainPainter: layer, grid and palette are all required.")
		return

	layer.clear()
	for y in grid.size.y:
		for x in grid.size.x:
			var cell := Vector2i(x, y)
			if not palette.has_symbol(grid.get_symbol(cell)):
				continue
			var placement := resolve_cell(grid, palette, cell, rng)
			layer.set_cell(
				origin + cell,
				palette.source_id,
				placement.atlas_coords,
				placement.alternative_tile
			)


## Picks the sprite for [param cell] from its neighbourhood. Pass an [param rng]
## to let the palette's alternative end variants show up.
static func resolve_cell(
	grid: WFCTerrainGrid,
	palette: WFCTilePalette,
	cell: Vector2i,
	rng: RandomNumberGenerator = null
) -> TilePlacement:
	var symbol := grid.get_symbol(cell)
	if grid.is_solid(cell + Vector2i(0, 1)):
		return TilePlacement.new(palette.get_body_tile(symbol))

	var open_left := not grid.is_solid(cell + Vector2i(-1, 0))
	var open_right := not grid.is_solid(cell + Vector2i(1, 0))
	var end_side := 0
	if open_left and not open_right:
		end_side = -1
	elif open_right and not open_left:
		end_side = 1

	var use_alt := rng != null and rng.randf() < 0.5
	var atlas := palette.get_underside_tile(symbol, end_side, use_alt)
	# The sheet only draws left hand ends, so mirror the sprite for right hand ones.
	return TilePlacement.new(atlas, FLIP_H if end_side > 0 else 0)
