extends Node2D

# Grid constants
@export var HEX_SIZE: float = 64
@export var GRID_COUNT: Vector2i = Vector2i(466,214)
@export var biomeGenScene: PackedScene
@export var meeple_control: Node2D
@export var debug_hex_prefab: PackedScene
const SQRT_3 = (111.0 / 128.0) * 2

var biomeGen = null
var created = false
var grid: Array = [] 


@onready var white_border: TileMapLayer = $"White Border"
@onready var black_border: TileMapLayer = $"Black Border"
@onready var interior: TileMapLayer = $Interior

const border_colours: PackedInt32Array = [1, 13, 14, 15, 16]

#[forest, tundra, water, sand, rainforest, plains, grassland, stone, iron, ruby, diamond]
const traversal_difficulty_by_biome = [0.25, 0.5, 1.0, 0.75, 0.15, 1.0, 0.8, 1.0, 0.75, 0.75, 0.5]

const HEX_DIRS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1)
]

var astar = AStar2D.new()

var terrainOffset = null

const FLAG_VERBOSE = false

class tile:
	var hex: Vector2i # (q, r)
	var classification: int = 0 # 0 is empty, 1 is obstruction, 2 is building, and 3 is stationary meeple, 4 is moving meeple
	var traversable: bool = true
	var traversal_difficulty: float = 1.0 # Must be nonzero for AStar (i think?)
	var biome: int = 0 # 0 is undefined biome
	var objectsInside: Array = []
	var queue: Array = []
	func _init(init_hex, _classification = 0):
		self.hex = init_hex
		self.classification = _classification
		self.traversable = (classification == 0 || classification == 4 || classification==3) # Only traversable if empty or moving meeple


func update_grid(hex: Vector2i, classification: int, objects: Array):
	var tile_to_update = grid[hex.x][hex.y]
	tile_to_update.classification = classification ### !!! ATTENTION !!! THIS UPDATES TILE TRAVERSABLE 
	tile_to_update.traversable = (classification==0 || classification==4 || classification==3)
	tile_to_update.objectsInside = objects
	astar.set_point_disabled(_hex_to_id(hex), !tile_to_update.traversable)
	white_border.set_cell(tile_to_update.hex, border_colours[tile_to_update.classification], Vector2i(0, 0))


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
func coord_to_axial_hex(coordinate: Vector2):
	var q = (1 / SQRT_3  * coordinate.x - 1.0 / (SQRT_3 * SQRT_3) * coordinate.y) / HEX_SIZE
	var r = (2.0 / 3.0 * coordinate.y) / HEX_SIZE
	if _hex_in_bounds(Vector2i(q, r)):
		return _hex_round(Vector2(q, r))
	else:
		return Vector2i(-1, -1)


func axial_hex_to_coord(hex: Vector2i):
	var x: float = HEX_SIZE * SQRT_3 * (hex.x + hex.y * 0.5)
	var y: float = HEX_SIZE * 3.0 / 2 * hex.y
	return Vector2(x, y)

	
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
			astar.add_point(id, t.hex, t.traversal_difficulty)
			astar.set_point_disabled(id, !t.traversable)
				
	for q in range(GRID_COUNT.x):
		for r in range(GRID_COUNT.y):
			var t: tile = grid[q][r]
			var id = _hex_to_id(t.hex)
			#if !t.traversable:
			#	continue
			for direction in HEX_DIRS:
				var next_hex = t.hex + direction
				if !_hex_in_bounds(next_hex):
					continue
				#var next_tile = grid[next_hex.x][next_hex.y]
				#if next_tile.traversable:
				astar.connect_points(id, _hex_to_id(next_hex), false)
					#print(id, " --> ", _hex_to_id(next_hex))


func find_path(start_hex: Vector2i, end_hex: Vector2i, partialPathBoolean, attackingBoolean):
	var start_id = _hex_to_id(start_hex)
	var end_id = _hex_to_id(end_hex)
	astar.set_point_disabled(start_id, false)
	# Check that destined grid spot is available
	#if (grid[end_hex.x][end_hex.y].classification == 2):
		#return [start_hex]
	
	if (grid[end_hex.x][end_hex.y].classification == 3 and !attackingBoolean):
		astar.set_point_disabled(end_id, false)

	var path_ids = astar.get_id_path(start_id, end_id, partialPathBoolean) # maybe allow partial paths?
	astar.set_point_disabled(end_id, !grid[end_hex.x][end_hex.y].traversable)
	
	if path_ids.size() == 0:
		return [start_hex]
	var path_hexes: Array[Vector2i] = []
	for id in path_ids: # Unflatten path_ids
		var q: int = id % GRID_COUNT.x
		var r: int = int(1.0 * id / GRID_COUNT.x) #1.0 for floating division
		path_hexes.append(Vector2i(q, r))
	return path_hexes


func redirected_find_path(path, partialPathBoolean, attackingBoolean, pathToDisable):
	var pathsCheck = []
	for h in pathToDisable:
		astar.set_point_disabled(_hex_to_id(h), 1)
		pathsCheck.append(astar.is_point_disabled(_hex_to_id(h)))
	var new_path = find_path(path[0], path[path.size() - 1], partialPathBoolean, attackingBoolean)
	
	for h in range(pathToDisable.size()):
		astar.set_point_disabled(_hex_to_id(pathToDisable[h]), pathsCheck[h])
	return new_path


func hex_ingress(ingressing_hex, meeple_requesting):
	var decision = "REDIRECTED"
	var decision_made = false
	var ingressing_tile = grid[ingressing_hex.x][ingressing_hex.y]
	if len(ingressing_tile.queue) > 0:
		#ingressing_tile.queue.push_back(meeple_requesting)
		#meeple_requesting.inqueue = true
		#if FLAG_VERBOSE: print("Adding another meeple, ", meeple_requesting.UNIQUEID, " to the queue on hex ", ingressing_tile.hex)
		#decision = "PENDING"
		#decision_made = true
		decision = "REDIRECTED"
		decision_made = true
	elif ingressing_tile.classification == 0:
		update_grid(ingressing_hex, 4, [meeple_requesting] + ingressing_tile.objectsInside)
		decision = "APPROVED"
		decision_made = true
	elif ingressing_tile.classification != 3 && ingressing_tile.classification != 4:
		decision = "REDIRECTED"
		decision_made = true
	# Check if the meeple is on the same team -> if not, attack!
	# From now on, assuming the meeple in ingressing_hex is the same team as meeple_requesting
	if !decision_made:
		var meeple_in_ingressing_hex = ingressing_tile.objectsInside[0]
		if (meeple_in_ingressing_hex.path[meeple_in_ingressing_hex.path.size() - 1] == meeple_requesting.path[meeple_requesting.path.size() - 1]):
			meeple_control.meeple_start_merge(meeple_in_ingressing_hex)
			#update_grid(ingressing_hex, 3, [meeple_requesting] + ingressing_tile.objectsInside)
			decision = "APPROVED"
		if !meeple_in_ingressing_hex.waiting:
			# 2 path, because the meeple in ingressing hex is moving, so it has initial hex, and target hex
			if (ingressing_tile.classification == 4 and len(meeple_in_ingressing_hex.path) > 2) or (ingressing_tile.classification == 3 and len(meeple_in_ingressing_hex.path) > 2):
				ingressing_tile.queue.push_back(meeple_requesting)
				meeple_requesting.inqueue = true
				if FLAG_VERBOSE: print("Queing a meeple, ", meeple_requesting.UNIQUEID, " to the queue on hex ", ingressing_tile.hex)
				decision = "PENDING"
	if FLAG_VERBOSE: print("Meeple ", meeple_requesting.UNIQUEID, " ingress request to ", ingressing_hex, " - Granted: ", decision)
	return decision


func hex_egress(egressing_hex):
	var egressing_hex_tile = grid[egressing_hex.x][egressing_hex.y]
	#var egressing_meeple = egressing_hex_tile.objectsInside[0]
	if len(egressing_hex_tile.queue) == 0:
		update_grid(egressing_hex, 0, egressing_hex_tile.objectsInside.slice(1)) # Removes meeple from grid
	else:
		var collected_meeple = egressing_hex_tile.queue.pop_front()
		collected_meeple.inqueue = false
		if FLAG_VERBOSE: print("Collecting meeple, ", collected_meeple.UNIQUEID, " from queue on hex ", egressing_hex)
		update_grid(egressing_hex, 4, [collected_meeple])
		meeple_control.egress_granted(collected_meeple)
		hex_egress(collected_meeple.path[0])


func _ready():
	#for i in range(0, 1000):
		#var test_hex = Vector2i(i,i)
		#if coord_to_axial_hex(axial_hex_to_coord(test_hex)) != test_hex:
			#print(test_hex)
			#print(axial_hex_to_coord(test_hex))
			#print(coord_to_axial_hex(axial_hex_to_coord(test_hex)))
			#
	terrainOffset = int(HEX_SIZE * SQRT_3 * (GRID_COUNT.y * 0.5))
	biomeGen = biomeGenScene.instantiate()
	biomeGen.terrainOffset = terrainOffset
	biomeGen.grid = self
	add_child(biomeGen)
	for q in range(GRID_COUNT.x):
		var row: Array = []
		for r in range(GRID_COUNT.y):
			var tileToCreate = tile.new(Vector2i(q, r))
			var center = axial_hex_to_coord(tileToCreate.hex)
			if center.x > terrainOffset and center.x < (biomeGen.MAP_RESOLUTION.x * biomeGen.PIXELS_PER_TILE) + terrainOffset:
				var index = Vector2i(
					int(floor((center.x - terrainOffset) / biomeGen.getPixelsPerTile())),
					int(floor((center.y) / biomeGen.getPixelsPerTile()))
				)
				#[Forest, Tundra, Water, Sand, rainforest, Plains, Grassland]
				if index.x <= biomeGen.MAP_RESOLUTION.x and index.y <= biomeGen.MAP_RESOLUTION.y:
					if biomeGen.debuggingGrid == false:
						const def = Vector2i(0, 0)
						var new_hex_debug = debug_hex_prefab.instantiate()
						#new_hex_debug.position = center
						add_child(new_hex_debug)
						black_border.set_cell(tileToCreate.hex, 0, def)
						white_border.set_cell(tileToCreate.hex, 1, def)
						interior.set_cell(tileToCreate.hex, 2 + biomeGen.map[index.y][index.x], def)
					tileToCreate.biome = biomeGen.map[index.y][index.x]
					if tileToCreate.biome == 2: #water
						tileToCreate.traversable = false
					tileToCreate.traversal_difficulty = 1 / traversal_difficulty_by_biome[biomeGen.map[index.y][index.x]]
			row.append(tileToCreate)
		grid.append(row)
	update_astar()


#func _process(_delta):
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#draw_debug_square()
#
#
#var debug_points = []
#func draw_debug_square():
	#var mouse_pos = get_global_mouse_position()
	#var center = Vector2i(mouse_pos)
	#const square_radius = 100
	#for x in range(center.x - square_radius, center.x + square_radius):
		#for y in range(center.y - square_radius, center.y + square_radius):
			#var pos = Vector2(x, y)
			#var color = color_from_cell(coord_to_axial_hex(pos))
			#debug_points.append({ "pos": pos, "color": color })
	#queue_redraw()
#
#
#func color_from_cell(cell: Vector2i) -> Color:
	#var hash = int(cell.x) * 73856093 ^ int(cell.y) * 19349663
	## Extract pseudo-random RGB from hash
	#var r = float((hash >> 16) & 0xFF) / 255.0
	#var g = float((hash >> 8) & 0xFF) / 255.0
	#var b = float(hash & 0xFF) / 255.0
	#return Color(r, g, b, 1)  # 50% opacity
#
#
#func _draw():
	#for point in debug_points:
		#draw_rect(Rect2(point.pos, Vector2(1, 1)), point.color)
