class_name WFCRuleSet
extends Resource
## The compiled tile alphabet a [WFCSolver] works on.
##
## Authors only fill in [member chunks]; calling [method compile] expands them
## into variants (adding mirrored copies where [member WFCChunk.allow_flip_h] is
## set) and derives the adjacency table from the chunk patterns. The result is
## pure data, which keeps the solver free of any scene or tile map knowledge.

## Neighbour directions, indexed the same way as [member WFCChunk.Side].
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]

const DIRECTION_COUNT := 4

## Edge length of every chunk, in tile map cells.
@export var chunk_size: int = 4

## Building blocks the solver may place.
@export var chunks: Array[WFCChunk] = []

## Terrain symbol to tile mapping used once the layout is painted.
@export var palette: WFCTilePalette

## When true the space outside the grid counts as empty, so chunks may only
## touch a border with an edge that is entirely empty.
@export var closed_borders: bool = true

var _variant_chunks: Array[WFCChunk] = []
var _variant_rows: Array[PackedStringArray] = []
var _variant_sockets: Array[PackedStringArray] = []
var _variant_flipped: PackedByteArray = PackedByteArray()
var _weights: PackedFloat32Array = PackedFloat32Array()
## [direction][variant] -> bit set of variants allowed on that side.
var _adjacency: Array[Array] = []
## [direction] -> bit set of variants whose edge on that side is empty.
var _border_masks: Array[PackedInt32Array] = []
var _compiled := false


## Expands [member chunks] into variants and derives the adjacency table.
## Returns [code]false[/code] when a chunk pattern is not a valid square.
func compile() -> bool:
	_variant_chunks.clear()
	_variant_rows.clear()
	_variant_sockets.clear()
	_variant_flipped = PackedByteArray()
	_weights = PackedFloat32Array()
	_compiled = false

	for chunk in chunks:
		if chunk == null:
			continue
		if not chunk.is_valid(chunk_size):
			push_error("WFCRuleSet: chunk '%s' is not a %dx%d square." % [chunk.id, chunk_size, chunk_size])
			return false
		var rows := chunk.get_rows()
		_add_variant(chunk, rows, false)
		if chunk.allow_flip_h:
			var mirrored := WFCChunk.mirror_rows(rows)
			if mirrored != rows:
				_add_variant(chunk, mirrored, true)

	if _variant_chunks.is_empty():
		push_error("WFCRuleSet: no usable chunks.")
		return false

	_build_adjacency()
	_build_border_masks()
	_compiled = true
	return true


func is_compiled() -> bool:
	return _compiled


func get_variant_count() -> int:
	return _variant_chunks.size()


func get_variant_id(variant: int) -> StringName:
	var chunk := _variant_chunks[variant]
	if _variant_flipped[variant] == 1:
		return StringName("%s_flipped" % chunk.id)
	return chunk.id


func get_variant_rows(variant: int) -> PackedStringArray:
	return _variant_rows[variant]


func get_variant_socket(variant: int, side: WFCChunk.Side) -> String:
	return _variant_sockets[variant][side]


func get_weights() -> PackedFloat32Array:
	return _weights


## Bit set of variants that may sit on the given neighbour side of [param variant].
func get_allowed(direction: int, variant: int) -> PackedInt32Array:
	return _adjacency[direction][variant]


## Bit set of variants whose edge facing [param direction] is empty.
func get_border_mask(direction: int) -> PackedInt32Array:
	return _border_masks[direction]


## Bit set of variants allowed on chunk-grid row [param row].
func get_row_mask(row: int) -> PackedInt32Array:
	_ensure_compiled()
	var mask := WFCBitSet.create_empty(get_variant_count())
	for variant in get_variant_count():
		var chunk := _variant_chunks[variant]
		if chunk.row_min >= 0 and row < chunk.row_min:
			continue
		if chunk.row_max >= 0 and row > chunk.row_max:
			continue
		WFCBitSet.enable(mask, variant)
	return mask


## Bit set of variants whose chunk carries [param tag].
func get_tag_mask(tag: String) -> PackedInt32Array:
	_ensure_compiled()
	var mask := WFCBitSet.create_empty(get_variant_count())
	for variant in get_variant_count():
		if _variant_chunks[variant].tags.has(tag):
			WFCBitSet.enable(mask, variant)
	return mask


## Reports chunks the solver can never place, which is the failure mode authored
## rules fail with: a chunk whose socket matches nothing just quietly stops
## appearing, and the levels look poorer for no visible reason.
##
## Pass [param row_masks] - one bit set per chunk-grid row - when a caller adds
## its own per-row restrictions, since those can strand a chunk the rule set on
## its own would place fine. Without them the grid is assumed tall enough that
## every row band is usable.
func validate(row_masks: Array[PackedInt32Array] = []) -> PackedStringArray:
	var problems := PackedStringArray()
	if not _compiled and not compile():
		problems.append("Rule set failed to compile.")
		return problems

	for variant in get_variant_count():
		if not _is_placeable(variant, row_masks):
			problems.append("'%s' can never be placed." % get_variant_id(variant))
	return problems


## Whether some chunk-grid row exists where this variant survives its own band,
## the caller's restrictions and its neighbours on all four sides.
func _is_placeable(variant: int, row_masks: Array[PackedInt32Array]) -> bool:
	var row_count := row_masks.size()
	var chunk := _variant_chunks[variant]
	var first := maxi(chunk.row_min, 0)
	var last := chunk.row_max if chunk.row_max >= 0 else maxi(row_count - 1, first)
	for row in range(first, last + 1):
		if row_count > 0:
			if row >= row_count:
				break
			if not WFCBitSet.has(row_masks[row], variant):
				continue
		if _has_neighbours_on_every_side(variant, row, row_masks):
			return true
	return false


func _has_neighbours_on_every_side(variant: int, row: int, row_masks: Array[PackedInt32Array]) -> bool:
	var row_count := row_masks.size()
	for direction in DIRECTION_COUNT:
		var step: Vector2i = DIRECTIONS[direction]
		var neighbour_row := row + step.y
		var off_grid := row_count > 0 and step.y != 0 and (neighbour_row < 0 or neighbour_row >= row_count)
		if off_grid:
			# Nothing to match against, so the border rule decides.
			if _can_sit_against_border(variant, direction):
				continue
			return false

		var allowed := get_allowed(direction, variant).duplicate()
		if step.y != 0 and row_count > 0:
			WFCBitSet.intersect(allowed, row_masks[neighbour_row])
		if WFCBitSet.is_empty(allowed) and not _can_sit_against_border(variant, direction):
			return false
	return true


## A chunk with no legal neighbour on a side can still be placed if that side is
## allowed to face out of the grid.
func _can_sit_against_border(variant: int, direction: int) -> bool:
	if not closed_borders:
		return true
	return WFCBitSet.has(_border_masks[direction], variant)


func _ensure_compiled() -> void:
	if not _compiled:
		compile()


## Renders a solved layout into a terrain grid of individual tile cells.
func stamp(variants: PackedInt32Array, grid_size: Vector2i) -> WFCTerrainGrid:
	var grid := WFCTerrainGrid.new(grid_size * chunk_size)
	for chunk_y in grid_size.y:
		for chunk_x in grid_size.x:
			var variant := variants[chunk_y * grid_size.x + chunk_x]
			if variant < 0:
				continue
			var rows := _variant_rows[variant]
			for row in chunk_size:
				for column in chunk_size:
					grid.set_symbol(
						Vector2i(chunk_x * chunk_size + column, chunk_y * chunk_size + row),
						rows[row][column]
					)
	return grid


func _add_variant(chunk: WFCChunk, rows: PackedStringArray, flipped: bool) -> void:
	var sockets := PackedStringArray()
	for side in DIRECTION_COUNT:
		sockets.append(WFCChunk.build_socket(rows, side))
	_variant_chunks.append(chunk)
	_variant_rows.append(rows)
	_variant_sockets.append(sockets)
	_variant_flipped.append(1 if flipped else 0)
	_weights.append(maxf(chunk.weight, 0.0001))


func _build_adjacency() -> void:
	var count := get_variant_count()
	_adjacency = []
	for direction in DIRECTION_COUNT:
		var per_variant: Array[PackedInt32Array] = []
		var opposite := (direction + 2) % DIRECTION_COUNT
		for variant in count:
			var allowed := WFCBitSet.create_empty(count)
			var socket := _variant_sockets[variant][direction]
			for neighbour in count:
				if _variant_sockets[neighbour][opposite] == socket:
					WFCBitSet.enable(allowed, neighbour)
			per_variant.append(allowed)
		_adjacency.append(per_variant)


func _build_border_masks() -> void:
	var count := get_variant_count()
	_border_masks = []
	for direction in DIRECTION_COUNT:
		var mask := WFCBitSet.create_empty(count)
		for variant in count:
			if WFCChunk.is_socket_empty(_variant_sockets[variant][direction]):
				WFCBitSet.enable(mask, variant)
		_border_masks.append(mask)
