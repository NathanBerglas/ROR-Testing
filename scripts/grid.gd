extends Node2D

# Grid constants
@export var HEX_SIZE: float = 100
@export var GRID_COUNT: Vector2i = Vector2i(19,11)

const SQRT_3 = 1.73205080757

var grid: Array = []

const HEX_DIRS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

var astar = AStar2D.new()

class tile:
	var hex: Vector2i # (q, r)
	var classification: int = 0 # 0 is empty, 1 is obstruction, 2 is building, and 3 is meeple
	var traversable = true
	var traversal_difficulty = 1.0 # Must be nonzero for AStar (i think?)
	var biome = 0 # 0 is undefined biome
	func _init(hex, _classification = 0):
		self.hex = hex
		self.classification = _classification
		self.traversable = (classification == 0) # Only traversable if empty

# Internal script to edit the grid, this is for placing a building, moving a meeple, etc.
func _update_grid(hex: Vector2i, classification: int):
	var tile_to_update = grid[hex.x][hex.y]
	if tile_to_update.classification == 0:
		grid[hex.x][hex.y] = tile.new(tile_to_update.hex, classification)
		return true
	else: # This grid point is not empty!
		return false # Throw error

#Added by Jacob -> External script that doesn't care about rules, set tile to that classification
#Chat if needed
func update_grid(hex: Vector2i, classification: int):
	var tile_to_update = grid[hex.x][hex.y]
	#print(classification)
	grid[hex.x][hex.y] = tile.new(tile_to_update.hex, classification)
	if classification != 0:
		astar.set_point_disabled(_hex_to_id(hex), true)
	#print(grid[hex.x][hex.y].classification)

#Added by Jacob -> Prob by takes axial Hex
func axial_probe(coordinate: Vector2i):
	var tile_pos: Vector2i = coordinate
	return grid[tile_pos.x][tile_pos.y]

# Takes the precise hex location and properly rounds it
func _hex_round(frac: Vector2) -> Vector2i:
	var x = frac.x
	var z = frac.y
	var y = -x - z

	var rx = round(x)
	var ry = round(y)
	var rz = round(z)

	var dx = abs(rx - x)
	var dy = abs(ry - y)
	var dz = abs(rz - z)

	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(rx, rz)

func _hex_in_bounds(hex: Vector2i) -> bool:
	return hex.x >= 0 and hex.y >= 0 \
		and hex.x < GRID_COUNT.x and hex.y < GRID_COUNT.y

# Takes the coordinates, ie. pixel position on map and coverts it to a hex position, ie. (q, r)
func coord_to_axial_hex(coordinate: Vector2i):
	var q: int = (SQRT_3 / 3.0 * coordinate.x - 1.0 / 3.0 * coordinate.y) / HEX_SIZE
	var r: int = (2.0 / 3.0 * coordinate.y) / HEX_SIZE
	if _hex_in_bounds(Vector2i(q, r)):
		return Vector2i(q, r)
	else:
		return Vector2(-1, -1)

func axial_hex_to_coord(hex: Vector2i):
	var x: int = HEX_SIZE * SQRT_3 * (hex.x + hex.y * 0.5)
	var y: int = HEX_SIZE * 1.5 * hex.y
	return Vector2i(x, y)

func hex_center(coordinate: Vector2i):
	return axial_hex_to_coord(coord_to_axial_hex(coordinate))

# Allow external scripts to check if a grid is empty, has a meeple, building, etc.
func probe(coordinate: Vector2i):
	var tile_pos: Vector2i = coord_to_axial_hex(coordinate)
	return grid[tile_pos.x][tile_pos.y]

# For AStar indexing. Simply flattens hex
func _hex_to_id(hex: Vector2i) -> int:
	return hex.y * GRID_COUNT.x + hex.x

func update_astar():
	astar.clear()
	
	for q in range(GRID_COUNT.x):
		for r in range(GRID_COUNT.y):
			var t: tile = grid[q][r]
			var id = _hex_to_id(t.hex)
			astar.add_point(_hex_to_id(t.hex), t.hex, t.traversal_difficulty)
			if !t.traversable: # Tile is not traversable
				astar.set_point_disabled(id, true)
				
	for q in range(GRID_COUNT.x):
		for r in range(GRID_COUNT.y):
			var t: tile = grid[q][r]
			var id = _hex_to_id(t.hex)
			if !t.traversable:
				continue
			for direction in HEX_DIRS:
				var next_hex = t.hex + direction
				if !_hex_in_bounds(next_hex):
					continue
				var next_tile = grid[next_hex.x][next_hex.y]
				if !next_tile.traversable:
					astar.connect_points(id, _hex_to_id(next_tile.hex), false)

func move_meeple(start_coord: Vector2i, end_coord: Vector2i):
	var start_hex = coord_to_axial_hex(start_coord)
	var start_id = _hex_to_id(start_hex)
	var end_hex = coord_to_axial_hex(end_coord)
	var end_id = _hex_to_id(end_hex)
	
	# Check that destined grid spot is available
	if !(grid[end_hex.x][end_hex.y].classification == 0) or !astar.is_point_disabled(start_id) or !astar.is_point_disabled(end_id):
		return []
	
	var path_ids = astar.get_id_path(start_id, end_id, false) # Do not allow partial paths
	var path_hexes: Array[Vector2i] = []
	
	for id in path_ids: # Unflatten path_ids
		var q: int = id % GRID_COUNT.x
		var r: int = id / GRID_COUNT.x
		path_hexes.append(Vector2i(q, r))
	return path_hexes

func _ready():
	for q in range(GRID_COUNT.x):
		var row: Array = []
		for r in range(GRID_COUNT.y):
			row.append(tile.new(Vector2i(q, r)))
		grid.append(row)
	update_astar()

func draw_hex(center: Vector2, size: float, color: Color) -> void:
	var points: PackedVector2Array = []
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30) # pointy-top
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
#
	for i in range(6):
		draw_line(points[i], points[(i + 1) % 6], color, 1.0)
	#
func _draw():
	for q in range(GRID_COUNT.x):
		for r in range(GRID_COUNT.y):
			var hex = Vector2i(q, r)
			var center = axial_hex_to_coord(hex)
			draw_hex(center, HEX_SIZE, Color.GRAY)
