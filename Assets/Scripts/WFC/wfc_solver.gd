class_name WFCSolver
extends RefCounted
## Wave Function Collapse over a grid of [WFCChunk] variants.
##
## Every cell starts with all variants possible. The solver repeatedly collapses
## the cell with the lowest entropy to a single weighted-random variant and
## propagates that choice through the adjacency table until no domain shrinks
## further. A contradiction restarts the whole grid with the next seed, which is
## cheaper and far simpler than backtracking at this grid size.
##
## The solver has no scene tree or tile map dependencies, so it can be driven
## directly from tests.

## How often the grid is re-rolled with a fresh seed before giving up.
const DEFAULT_MAX_ATTEMPTS := 16

var _rules: WFCRuleSet
var _size: Vector2i
var _seed: int
var _variant_count: int
var _weights: PackedFloat32Array
var _rng := RandomNumberGenerator.new()
## Domains as they look before solving, including every caller restriction.
var _initial_domains: Array[PackedInt32Array] = []
var _domains: Array[PackedInt32Array] = []
var _result: PackedInt32Array = PackedInt32Array()
var _pending: Array[int] = []
var _attempts_used := 0


func _init(rule_set: WFCRuleSet, grid_size: Vector2i, solver_seed: int = 0) -> void:
	if not rule_set.is_compiled():
		rule_set.compile()
	_rules = rule_set
	_size = grid_size
	_seed = solver_seed
	_variant_count = rule_set.get_variant_count()
	_weights = rule_set.get_weights()
	_reset_initial_domains()


## Restricts a single cell to the variants in [param mask]. Call before [method solve].
func restrict_cell(cell: Vector2i, mask: PackedInt32Array) -> void:
	if not _has_cell(cell):
		return
	WFCBitSet.intersect(_initial_domains[_cell_index(cell)], mask)


## Restricts a whole chunk-grid row, used for terrain bands.
func restrict_row(row: int, mask: PackedInt32Array) -> void:
	for x in _size.x:
		restrict_cell(Vector2i(x, row), mask)


## Applies the row bands authored on the chunks plus, when
## [member WFCRuleSet.closed_borders] is set, the empty-edge border rule.
func apply_default_constraints() -> void:
	for y in _size.y:
		restrict_row(y, _rules.get_row_mask(y))
	if not _rules.closed_borders:
		return
	for x in _size.x:
		restrict_cell(Vector2i(x, 0), _rules.get_border_mask(WFCChunk.Side.NORTH))
		restrict_cell(Vector2i(x, _size.y - 1), _rules.get_border_mask(WFCChunk.Side.SOUTH))
	for y in _size.y:
		restrict_cell(Vector2i(0, y), _rules.get_border_mask(WFCChunk.Side.WEST))
		restrict_cell(Vector2i(_size.x - 1, y), _rules.get_border_mask(WFCChunk.Side.EAST))


## Collapses the whole grid. Returns [code]false[/code] when every attempt hit a
## contradiction, in which case the rule set most likely has an unreachable
## combination of constraints.
func solve(max_attempts: int = DEFAULT_MAX_ATTEMPTS) -> bool:
	_attempts_used = 0
	for attempt in maxi(max_attempts, 1):
		_attempts_used = attempt + 1
		_rng.seed = _seed + attempt
		if _try_solve():
			return true
	return false


## Chunk variant chosen per cell, row-major. Empty until [method solve] succeeds.
func get_result() -> PackedInt32Array:
	return _result


## Number of solve attempts the last [method solve] call needed.
func get_attempts_used() -> int:
	return _attempts_used


## Convenience wrapper turning the solved layout into terrain cells.
func build_terrain_grid() -> WFCTerrainGrid:
	return _rules.stamp(_result, _size)


func _reset_initial_domains() -> void:
	_initial_domains = []
	for index in _size.x * _size.y:
		_initial_domains.append(WFCBitSet.create_full(_variant_count))


func _try_solve() -> bool:
	_domains = []
	for domain in _initial_domains:
		_domains.append(domain.duplicate())

	_pending.clear()
	for index in _domains.size():
		_pending.append(index)
	if not _propagate():
		return false

	while true:
		var cell_index := _find_lowest_entropy_cell()
		if cell_index < 0:
			break
		if not _collapse(cell_index):
			return false
		if not _propagate():
			return false

	_result = PackedInt32Array()
	_result.resize(_domains.size())
	for index in _domains.size():
		_result[index] = WFCBitSet.first(_domains[index])
	return true


## Index of the undecided cell with the lowest weighted entropy, or -1 when the
## grid is fully collapsed. Ties are broken by a small random offset so the
## traversal order does not bias the layout.
func _find_lowest_entropy_cell() -> int:
	var best_index := -1
	var best_entropy := INF
	for index in _domains.size():
		var options := WFCBitSet.count(_domains[index])
		if options <= 1:
			continue
		var entropy := _entropy(_domains[index]) + _rng.randf() * 0.0001
		if entropy < best_entropy:
			best_entropy = entropy
			best_index = index
	return best_index


func _entropy(domain: PackedInt32Array) -> float:
	var total := 0.0
	var total_log := 0.0
	for variant in WFCBitSet.to_indices(domain):
		var weight := _weights[variant]
		total += weight
		total_log += weight * log(weight)
	if total <= 0.0:
		return 0.0
	return log(total) - total_log / total


func _collapse(cell_index: int) -> bool:
	var options := WFCBitSet.to_indices(_domains[cell_index])
	if options.is_empty():
		return false

	var total := 0.0
	for variant in options:
		total += _weights[variant]

	var roll := _rng.randf() * total
	var chosen: int = options[options.size() - 1]
	for variant in options:
		roll -= _weights[variant]
		if roll <= 0.0:
			chosen = variant
			break

	var collapsed := WFCBitSet.create_empty(_variant_count)
	WFCBitSet.enable(collapsed, chosen)
	_domains[cell_index] = collapsed
	_pending.append(cell_index)
	return true


## Shrinks neighbour domains until nothing changes. Returns [code]false[/code]
## as soon as a cell runs out of options.
func _propagate() -> bool:
	while not _pending.is_empty():
		var cell_index: int = _pending.pop_back()
		if WFCBitSet.is_empty(_domains[cell_index]):
			return false
		var cell := _index_cell(cell_index)
		for direction in WFCRuleSet.DIRECTION_COUNT:
			var neighbour := cell + WFCRuleSet.DIRECTIONS[direction]
			if not _has_cell(neighbour):
				continue
			var neighbour_index := _cell_index(neighbour)
			var allowed := WFCBitSet.create_empty(_variant_count)
			for variant in WFCBitSet.to_indices(_domains[cell_index]):
				WFCBitSet.unite(allowed, _rules.get_allowed(direction, variant))
			if not WFCBitSet.intersect(_domains[neighbour_index], allowed):
				continue
			if WFCBitSet.is_empty(_domains[neighbour_index]):
				return false
			if not _pending.has(neighbour_index):
				_pending.append(neighbour_index)
	return true


func _has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


func _cell_index(cell: Vector2i) -> int:
	return cell.y * _size.x + cell.x


func _index_cell(index: int) -> Vector2i:
	return Vector2i(index % _size.x, index / _size.x)
