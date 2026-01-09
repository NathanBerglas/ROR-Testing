extends Node2D

# Grid constants
@export var HEX_SIZE: float = 100
@export var GRID_COUNT: Vector2i = Vector2i(19,11)

const SQRT_3 = 1.73205080757

var grid: Array = []


class tile:
	var hex: Vector2i # (q, r)
	var classification: int = 0 # 0 is empty, 1 is obstruction, 2 is building, and 3 is meeple
	
	func _init(hex, _classification = 0):
		hex = hex
		classification = _classification
	

# Internal script to edit the grid, this is for placing a building, moving a meeple, etc.
func _update_grid(hex: Vector2i, classification: int):
	var tile_to_update = grid[hex.x][hex.y]
	if tile_to_update.classification == 0:
		grid[hex.x][hex.y] = tile.new(tile_to_update.hex, classification)
		return true
	else: # This grid point is not empty!
		return false # Throw error


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


# Takes the coordinates, ie. pixel position on map and coverts it to a hex position, ie. (q, r)
func _coord_to_axial_hex(coordinate: Vector2i):
	var q: float = (SQRT_3 / 3.0 * coordinate.x - 1.0 / 3.0 * coordinate.y) / HEX_SIZE
	var r: float = (2.0 / 3.0 * coordinate.y) / HEX_SIZE
	return _hex_round(Vector2(q, r))


func _axial_hex_to_coord(hex: Vector2i):
	var x: float = HEX_SIZE * SQRT_3 * (hex.x + hex.y * 0.5)
	var y: float = HEX_SIZE * 1.5 * hex.y
	return Vector2(x, y)


# Allow external scripts to check if a grid is empty, has a meeple, building, etc.
func probe(coordinate: Vector2i):
	var tile_pos: Vector2i = _coord_to_axial_hex(coordinate)
	return grid[tile_pos.x][tile_pos.y]


# Grid interface for placing buildings on the grid
func order_building(coordinate: Vector2i):
	var tile_hex: Vector2i = _coord_to_axial_hex(coordinate)
	var tile_cord: Vector2i = _axial_hex_to_coord(coordinate)
	if _update_grid(tile_hex, 2):
		print("Buildaxial_to_worlding placement (@ coord", coordinate, "), is acceptable to grid, @ hex: ", tile_hex, ", and coord: ", tile_cord)
		return [true, tile_cord]
	else:
		print("Failed in updating, cord: ", tile_cord, ", tile cord:, ", tile_cord)
		return [false, tile_cord]
		
		
# Grid interface for spawning meeples on the grid
func order_meeple_spawn(coordinate: Vector2i):
	var tile_hex: Vector2i = _coord_to_axial_hex(coordinate)
	var tile_cord: Vector2i = _axial_hex_to_coord(tile_hex)
	if _update_grid(tile_hex, 3):
		print("Meeple spawn placement (@ coord", coordinate, "), is acceptable to grid, @ hex: ", tile_hex, ", and coord: ", tile_cord)
		return [true, tile_cord]
	else:
		print("Failed in updating @ requested coord: ", coordinate, ", @ hex: ", tile_hex, ", and hex coord: ", tile_cord)
		return [false, tile_cord]
		
		
func _ready():
	for q in range(GRID_COUNT.x):
		var row: Array = []
		for r in range(GRID_COUNT.y):
			row.append(tile.new(Vector2i(q, r)))
		grid.append(row)	
	
#func draw_hex(center: Vector2, size: float, color: Color) -> void:
	#var points: PackedVector2Array = []
	#for i in range(6):
		#var angle = deg_to_rad(60 * i - 30) # pointy-top
		#points.append(center + Vector2(cos(angle), sin(angle)) * size)
#
	#for i in range(6):
		#draw_line(points[i], points[(i + 1) % 6], color, 1.0)

# FOR TESTING!
func _process(delta):
	if Input.is_action_just_pressed("spawn_meeple"): #Testing purposes
		order_meeple_spawn(Vector2i(get_global_mouse_position()))
	#
#func _draw():
	#for q in range(GRID_COUNT.x):
		#for r in range(GRID_COUNT.y):
			#var hex = Vector2i(q, r)
			#var center = _axial_hex_to_coord(hex)
			#draw_hex(center, HEX_SIZE, Color.GRAY)
