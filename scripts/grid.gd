extends Node2D

# Grid constants
@export var HEX_SIZE: float = 100
@export var GRID_COUNT: Vector2i = Vector2i(25,20)
@export var arable_land_prefab: PackedScene
@export var forest_prefab: PackedScene
@export var stone_deposit_prefab: PackedScene
const SQRT_3 = 1.73205080757

var created = false
var grid: Array = []

@export var hex_prefab: PackedScene
const border_colours: PackedColorArray = [Color.DARK_GRAY, Color.DARK_RED, Color.SEA_GREEN, Color.STEEL_BLUE, Color.SKY_BLUE]

const HEX_DIRS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

var astar = AStar2D.new()

const TILE_TYPE_CHANCES = 15
const ARABLE_CHANCE = 1
const FOREST_CHANCE = 2
const STONE_CHANCE = 3

class tile:
	var hex: Vector2i # (q, r)
	var hex_pf: Node
	var classification: int = 0 # 0 is empty, 1 is obstruction, 2 is building, and 3 is stationary meeple, 4 is moving meeple
	var traversable: bool = true
	var traversal_difficulty: float = 1.0 # Must be nonzero for AStar (i think?)
	var biome: int = 0 # 0 is undefined biome
	var objectsInside: Array = []
	var type: String = "NULL"
	func _init(hex, _classification = 0):
		self.hex = hex
		self.classification = _classification
		self.traversable = (classification == 0) # Only traversable if empty
	
		var random = randi_range(0,TILE_TYPE_CHANCES)
		if random == ARABLE_CHANCE:
			self.type = "ARABLE"
		elif random == FOREST_CHANCE:
			self.type = "FOREST"
		elif random == STONE_CHANCE:
			self.type = "STONE"
		else:
			self.type = "BASIC_BITCH"


#Added by Jacob -> External script that doesn't care about rules, set tile to that classification
#Chat if needed
func update_grid(hex: Vector2i, classification: int, objects):
	var tile_to_update = grid[hex.x][hex.y]
	tile_to_update.classification = classification ### !!! ATTENTION !!! THIS UPDATES TILE TRAVERSABLE 
	tile_to_update.traversable = (classification==0 || classification==4)
	tile_to_update.objectsInside = objects
	astar.set_point_disabled(_hex_to_id(hex), !tile_to_update.traversable)
	tile_to_update.hex_pf.get_node("Border").modulate = border_colours[tile_to_update.classification]


#Added by Jacob -> Probe by takes axial Hex
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
	var q: float = (SQRT_3 / 3.0 * coordinate.x - 1.0 / 3.0 * coordinate.y) / HEX_SIZE
	var r: float = (2.0 / 3.0 * coordinate.y) / HEX_SIZE
	if _hex_in_bounds(Vector2i(q, r)):
		return _hex_round(Vector2(q, r))
	else:
		#print("Hex out of bound for coordinates: ", coordinate)
		return Vector2i(-1, -1)


func axial_hex_to_coord(hex: Vector2i):
	var x: float = HEX_SIZE * SQRT_3 * (hex.x + hex.y * 0.5)
	var y: float = HEX_SIZE * 1.5 * hex.y
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
				var next_tile = grid[next_hex.x][next_hex.y]
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
		var r: int = id / GRID_COUNT.x
		path_hexes.append(Vector2i(q, r))
		
	return path_hexes
	

func _ready():
	for q in range(GRID_COUNT.x):
		var row: Array = []
		for r in range(GRID_COUNT.y):
			var tileToCreate = tile.new(Vector2i(q, r))
			
			var new_hex = hex_prefab.instantiate()
			new_hex.position = axial_hex_to_coord(Vector2i(q, r))
			new_hex.scale = Vector2i(1, 1) * HEX_SIZE / 100 * 2
			new_hex.get_node("Border").modulate = Color.DARK_GRAY 
			self.add_child(new_hex)
			tileToCreate.hex_pf = new_hex
			
			if tileToCreate.type == "ARABLE":
				var instance = arable_land_prefab.instantiate()
				# Set instance's data
				instance.global_position = axial_hex_to_coord(tileToCreate.hex)
				add_child(instance)
			elif tileToCreate.type == "FOREST":
				var instance = forest_prefab.instantiate()
				# Set instance's data
				instance.global_position = axial_hex_to_coord(tileToCreate.hex)
				add_child(instance)
			elif tileToCreate.type == "STONE":
				var instance = stone_deposit_prefab.instantiate()
				# Set instance's data
				instance.global_position = axial_hex_to_coord(tileToCreate.hex)
				add_child(instance)
		
			row.append(tileToCreate)
		grid.append(row)
	update_astar()
