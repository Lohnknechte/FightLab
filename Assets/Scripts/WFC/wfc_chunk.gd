class_name WFCChunk
extends Resource
## One authored building block of a Wave Function Collapse level.
##
## A chunk is a small square patch of terrain drawn as text, e.g. a 4x4 patch
## where [code].[/code] is empty space and every other symbol is a terrain that
## [WFCTilePalette] knows how to paint:
## [codeblock]
## ....
## GGGG
## DDDD
## ....
## [/codeblock]
## Adjacency is derived from the patch itself - see [method get_socket] - so
## authoring a chunk never means hand writing rules that can drift out of sync
## with the drawing.

## Empty space. Any other symbol counts as solid terrain.
const EMPTY_SYMBOL := "."

enum Side { NORTH, EAST, SOUTH, WEST }

## Identifies the chunk in logs and in [member WFCRuleSet.get_variant_id].
@export var id: StringName = &""

## The terrain patch, one line per row. Must be square.
@export_multiline var pattern: String = ""

## Relative likelihood of this chunk when the solver collapses a cell.
@export_range(0.0, 32.0, 0.01) var weight: float = 1.0

## When true a horizontally mirrored copy is added to the rule set as well.
@export var allow_flip_h: bool = false

## Lowest chunk-grid row this chunk may occupy, or -1 for no lower bound.
@export var row_min: int = -1

## Highest chunk-grid row this chunk may occupy, or -1 for no upper bound.
@export var row_max: int = -1

## Free-form labels the level generator can target, e.g. "ground" or "spawnable".
@export var tags: PackedStringArray = PackedStringArray()


## The pattern split into rows, ignoring blank lines and surrounding whitespace.
func get_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	for line in pattern.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.is_empty():
			rows.append(trimmed)
	return rows


## Returns the chunk edge length, or 0 when the pattern is not a valid square.
func get_size() -> int:
	var rows := get_rows()
	if rows.is_empty():
		return 0
	for row in rows:
		if row.length() != rows.size():
			return 0
	return rows.size()


func is_valid(expected_size: int) -> bool:
	return get_size() == expected_size and expected_size > 0


## Edge profile used for adjacency matching.
##
## Horizontal sides are read top to bottom and vertical sides left to right, so
## two chunks fit together when the socket facing the seam is identical on both
## sides. Solid symbols are kept as-is, which means terrains only line up with
## the same terrain along a seam.
static func build_socket(rows: PackedStringArray, side: int) -> String:
	var size := rows.size()
	var socket := ""
	match side:
		Side.NORTH:
			socket = rows[0]
		Side.SOUTH:
			socket = rows[size - 1]
		Side.WEST:
			for row in rows:
				socket += row[0]
		Side.EAST:
			for row in rows:
				socket += row[size - 1]
	return socket


## A horizontally mirrored copy of [param rows].
static func mirror_rows(rows: PackedStringArray) -> PackedStringArray:
	var mirrored := PackedStringArray()
	for row in rows:
		mirrored.append(row.reverse())
	return mirrored


static func is_socket_empty(socket: String) -> bool:
	for index in socket.length():
		if socket[index] != EMPTY_SYMBOL:
			return false
	return true
