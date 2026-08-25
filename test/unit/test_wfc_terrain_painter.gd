extends GutTest
## Unit tests for the tile selection in wfc_terrain_painter.gd.
##
## Picking the sprite is pure neighbourhood logic, so it is checked without a
## tile map. Painting into a real layer is covered by the component test.

const PALETTE_PATH := "res://Assets/Scripts/WFC/RuleSets/bloecke_palette.tres"

var _palette: WFCTilePalette
var _grid: WFCTerrainGrid


func before_each() -> void:
	_palette = load(PALETTE_PATH)
	_grid = WFCTerrainGrid.new(Vector2i(5, 3))


func test_a_covered_cell_uses_the_plain_body_tile() -> void:
	_grid.set_symbol(Vector2i(2, 0), "G")
	_grid.set_symbol(Vector2i(2, 1), "D")

	var placement := WFCTerrainPainter.resolve_cell(_grid, _palette, Vector2i(2, 0))

	assert_eq(placement.atlas_coords, _palette.get_body_tile("G"))
	assert_eq(placement.alternative_tile, 0)


func test_an_exposed_underside_uses_the_carved_tile() -> void:
	for x in range(1, 4):
		_grid.set_symbol(Vector2i(x, 1), "G")

	var placement := WFCTerrainPainter.resolve_cell(_grid, _palette, Vector2i(2, 1))

	assert_eq(placement.atlas_coords, _palette.underside_tiles["G"])
	assert_eq(placement.alternative_tile, 0)


func test_a_left_hand_end_uses_the_end_tile_unmirrored() -> void:
	_grid.set_symbol(Vector2i(1, 1), "G")
	_grid.set_symbol(Vector2i(2, 1), "G")

	var placement := WFCTerrainPainter.resolve_cell(_grid, _palette, Vector2i(1, 1))

	assert_eq(placement.atlas_coords, _palette.end_tiles["G"])
	assert_eq(placement.alternative_tile, 0)


func test_a_right_hand_end_mirrors_the_same_tile() -> void:
	_grid.set_symbol(Vector2i(1, 1), "G")
	_grid.set_symbol(Vector2i(2, 1), "G")

	var placement := WFCTerrainPainter.resolve_cell(_grid, _palette, Vector2i(2, 1))

	assert_eq(placement.atlas_coords, _palette.end_tiles["G"])
	assert_eq(placement.alternative_tile, WFCTerrainPainter.FLIP_H)


func test_terrains_without_variants_fall_back_to_the_body_tile() -> void:
	_grid.set_symbol(Vector2i(2, 1), "S")

	var placement := WFCTerrainPainter.resolve_cell(_grid, _palette, Vector2i(2, 1))

	assert_eq(placement.atlas_coords, _palette.get_body_tile("S"))


func test_the_palette_offers_an_alternative_end_variant() -> void:
	assert_ne(_palette.get_underside_tile("G", -1, false), _palette.get_underside_tile("G", -1, true))
	assert_eq(_palette.get_underside_tile("G", -1, true), _palette.end_alt_tiles["G"])
