class_name WFCReachability
extends RefCounted
## Works out which parts of a generated arena players can actually move between.
##
## Standing spots become nodes and single jumps become directed edges, because
## reachability is not symmetric: dropping into a pit is always possible, and
## climbing back out often is not. Grouping the graph into strongly connected
## components therefore answers the question that matters for a fighting arena -
## "can everyone reach everyone else" - which plain connected components would
## quietly get wrong.
##
## Jump arcs are not traced against the terrain. The one blocker that is checked
## is a ceiling directly above the take-off, which is the case that actually
## comes up in these layouts; anything subtler is left to
## [member WFCMovementProfile.safety_margin].

var _grid: WFCTerrainGrid
var _profile: WFCMovementProfile
var _cells: Array[Vector2i] = []
var _index_of: Dictionary = {}
var _edges: Array[PackedInt32Array] = []
var _reverse_edges: Array[PackedInt32Array] = []
var _components: Array[Array] = []


func _init(grid: WFCTerrainGrid, profile: WFCMovementProfile) -> void:
	_grid = grid
	_profile = profile
	_cells = grid.find_standable_cells(profile.head_room)
	for index in _cells.size():
		_index_of[_cells[index]] = index
	_build_edges()
	_build_components()


## Every surface cell a character can stand on.
func get_cells() -> Array[Vector2i]:
	return _cells


## Whether a single jump gets from [param from] to [param to].
func has_edge(from: Vector2i, to: Vector2i) -> bool:
	if not _index_of.has(from) or not _index_of.has(to):
		return false
	return _edges[_index_of[from]].has(_index_of[to])


## Groups of cells that can all reach each other, largest first.
func get_components() -> Array[Array]:
	return _components


## The biggest mutually reachable area, which is where spawn points belong.
func get_largest_component() -> Array[Vector2i]:
	if _components.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	return _components[0]


## Whether [param a] and [param b] can reach each other in both directions.
func are_mutually_reachable(a: Vector2i, b: Vector2i) -> bool:
	for component in _components:
		if component.has(a):
			return component.has(b)
	return false


func _build_edges() -> void:
	_edges = []
	_reverse_edges = []
	for index in _cells.size():
		_edges.append(PackedInt32Array())
		_reverse_edges.append(PackedInt32Array())

	for from_index in _cells.size():
		for to_index in _cells.size():
			if from_index == to_index:
				continue
			var delta: Vector2i = _cells[to_index] - _cells[from_index]
			if not _profile.can_traverse(delta):
				continue
			if delta.y < 0 and not _has_take_off_clearance(_cells[from_index], -delta.y):
				continue
			_edges[from_index].append(to_index)
			_reverse_edges[to_index].append(from_index)


## A jump only gains height if nothing is bolted to the ceiling above the
## character's head at the take-off point.
func _has_take_off_clearance(cell: Vector2i, rise: int) -> bool:
	for offset in range(1, rise + _profile.head_room + 1):
		if _grid.is_solid(cell + Vector2i(0, -offset)):
			return false
	return true


## Kosaraju's algorithm: order the nodes by depth first finish time, then walk
## the reversed graph in that order. Both passes use an explicit stack because a
## large arena would otherwise recurse deeper than GDScript is comfortable with.
func _build_components() -> void:
	_components = []
	var count := _cells.size()
	if count == 0:
		return

	var order := _order_by_finish_time(count)
	var component_of := PackedInt32Array()
	component_of.resize(count)
	component_of.fill(-1)

	var grouped: Array[Array] = []
	for position in range(order.size() - 1, -1, -1):
		var root: int = order[position]
		if component_of[root] != -1:
			continue
		var members: Array[Vector2i] = []
		var stack: Array[int] = [root]
		component_of[root] = grouped.size()
		while not stack.is_empty():
			var node: int = stack.pop_back()
			members.append(_cells[node])
			for previous in _reverse_edges[node]:
				if component_of[previous] == -1:
					component_of[previous] = grouped.size()
					stack.append(previous)
		grouped.append(members)

	grouped.sort_custom(func(a, b): return a.size() > b.size())
	_components = grouped


func _order_by_finish_time(count: int) -> PackedInt32Array:
	var visited := PackedByteArray()
	visited.resize(count)
	visited.fill(0)
	var order := PackedInt32Array()

	for start in count:
		if visited[start] == 1:
			continue
		visited[start] = 1
		var stack: Array[int] = [start]
		var next_edge: Array[int] = [0]
		while not stack.is_empty():
			var node: int = stack[stack.size() - 1]
			var edge_index: int = next_edge[next_edge.size() - 1]
			if edge_index < _edges[node].size():
				next_edge[next_edge.size() - 1] = edge_index + 1
				var neighbour: int = _edges[node][edge_index]
				if visited[neighbour] == 0:
					visited[neighbour] = 1
					stack.append(neighbour)
					next_edge.append(0)
			else:
				order.append(node)
				stack.pop_back()
				next_edge.pop_back()
	return order
