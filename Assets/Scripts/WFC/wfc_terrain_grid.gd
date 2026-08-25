class_name WFCTerrainGrid
extends RefCounted
## A solved layout expanded to one terrain symbol per tile map cell.
##
## This is the hand-off point between the solver and the rest of the game: the
## painter turns it into tiles and the level generator reads it to find standing
## room for spawn points and hazards.

const EMPTY_SYMBOL := WFCChunk.EMPTY_SYMBOL

var size: Vector2i

var _symbols: PackedByteArray = PackedByteArray()


func _init(grid_size: Vector2i = Vector2i.ZERO) -> void:
	resize(grid_size)


func resize(grid_size: Vector2i) -> void:
	size = Vector2i(maxi(grid_size.x, 0), maxi(grid_size.y, 0))
	_symbols = PackedByteArray()
	_symbols.resize(size.x * size.y)
	_symbols.fill(EMPTY_SYMBOL.unicode_at(0))


## Builds a grid from the same text layout [method to_text] prints, which keeps
## debugging and tests working in the notation the chunks are authored in.
static func from_text(text: String) -> WFCTerrainGrid:
	var rows := PackedStringArray()
	var width := 0
	for line in text.split("
"):
		var trimmed := line.strip_edges()
		if trimmed.is_empty():
			continue
		rows.append(trimmed)
		width = maxi(width, trimmed.length())

	var grid := WFCTerrainGrid.new(Vector2i(width, rows.size()))
	for y in rows.size():
		for x in rows[y].length():
			grid.set_symbol(Vector2i(x, y), rows[y][x])
	return grid


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func get_symbol(cell: Vector2i) -> String:
	if not has_cell(cell):
		return EMPTY_SYMBOL
	return char(_symbols[cell.y * size.x + cell.x])


func set_symbol(cell: Vector2i, symbol: String) -> void:
	if not has_cell(cell) or symbol.is_empty():
		return
	_symbols[cell.y * size.x + cell.x] = symbol.unicode_at(0)


## Cells outside the grid count as empty, which keeps neighbour lookups simple.
func is_solid(cell: Vector2i) -> bool:
	return get_symbol(cell) != EMPTY_SYMBOL


## A solid cell that a character can stand on: empty above with head room.
func is_standable(cell: Vector2i, head_room: int = 2) -> bool:
	if not is_solid(cell):
		return false
	for offset in range(1, head_room + 1):
		if is_solid(cell + Vector2i(0, -offset)):
			return false
	return true


func count_solid() -> int:
	var total := 0
	var empty_code := EMPTY_SYMBOL.unicode_at(0)
	for index in _symbols.size():
		if _symbols[index] != empty_code:
			total += 1
	return total


## Every cell a character could stand on, scanned top-left to bottom-right.
func find_standable_cells(head_room: int = 2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if is_standable(cell, head_room):
				cells.append(cell)
	return cells


## Debug helper mirroring the authoring format of [member WFCChunk.pattern].
func to_text() -> String:
	var lines := PackedStringArray()
	for y in size.y:
		var line := ""
		for x in size.x:
			line += get_symbol(Vector2i(x, y))
		lines.append(line)
	return "\n".join(lines)
