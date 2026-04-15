extends Node2D

const FLAG_VERBOSE = false
const debuggingGrid = false
# Main Area
#@export var SCREEN_RESOLUTION: Vector2i = Vector2i(1920,1080)
#@export var COLS: int = 192
#var PIXELS_PER_TILE: int

# Map Area
@export var BORDER_RESOLUTION: int = 40
@export var BEACH_RESOLUTION: int = 10
@export var PIXELS_PER_TILE: int = 10
var MAP_RESOLUTION: Vector2i = Vector2i(1080, 580)


# Gen Data
@export var gen_data: JSON
#[Forest, Tundra, Water, Sand, rainforest, Plains, Grassland, Stone, Iron, Ruby, Diamonds]
#Hardcode
@export var origin_radius = 10*10 # Squared
@export var biome_index: Array = [99, 0, 4, 1, 3, 6, 0, 5, 2]

var resource_index: Array = [7, 8, 9, 10]
#2: Water

# Debugging
@export var target: PackedScene

# Poisson distribution constants
const max_poisson_attempts_1d: int = 100
const max_poisson_attempts_2d: int = 500
const sphere_packing_constant: float = 0.9069

const warp_strength: float = 8.0   # How far borders get pushed (in cells)
const warp_frequency: float = 0.04 # Scale of the noise (smaller = smoother)
const noise_offset: float = 75.0  # Offset to decorrelate X and Y axes


#Data types sent over:
#[Forest, Tundra, Water, Sand, rainforest, Plains, Grassland]
var GLOBAL_CHUNK_COUNT = Vector2i()
var GLOBAL_chunk_length = float()

const RANDOM_BLOB_VARIATION = 3

const RESOURCE_WATER_OFFSET = 2 # defines when placing resources, how many pixels to offset them by if they are in water
var map = null

var scalingFactor = null
var terrainOffset = null

var grid = null

var waterAreas = [] #locations of water to not spawn stuff on


func point_chunk_print(point_chunk) -> void:
	var chunk_array = point_chunk[1]
	var chunk_dim = GLOBAL_CHUNK_COUNT
	for col in chunk_dim[0]:
		for row in chunk_dim[1]:
			if FLAG_VERBOSE: print("Chunk (",col, ", ", row, ")")
			if FLAG_VERBOSE: print(chunk_array[col-1][row-1])
func _ready() -> void:

	var previous_time = Time.get_ticks_msec()
	var ellapsed = 0
	# Main Area
	#PIXELS_PER_TILE = int(SCREEN_RESOLUTION.x / COLS)

	# Map Area
	#MAP_RESOLUTION = Vector2i(SCREEN_RESOLUTION.x + BORDER_RESOLUTION, SCREEN_RESOLUTION.y + 2 * BORDER_RESOLUTION)
	#MAP_RESOLUTION.x = MAP_RESOLUTION.x / PIXELS_PER_TILE
	#MAP_RESOLUTION.y = MAP_RESOLUTION.y / PIXELS_PER_TILE
	# Generate Mesh
	
	
		#Data returned: min_distance, feature name, spawn area, occurences, layer, roughness, radius, number of points, neighbour counts, point min Distance
		
	var data = get_data()
	
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	GLOBAL_chunk_length = data[0] * 0.70711 # min_distance / sqrt(2)
	if FLAG_VERBOSE: print("Data gotten: ", ellapsed)
	if FLAG_VERBOSE: print(GLOBAL_chunk_length)
	GLOBAL_CHUNK_COUNT = Vector2i(int(ceil((MAP_RESOLUTION.x - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE / GLOBAL_chunk_length)), int(ceil((MAP_RESOLUTION.y - BORDER_RESOLUTION * 2)  * PIXELS_PER_TILE / GLOBAL_chunk_length)))
	if FLAG_VERBOSE: print(GLOBAL_CHUNK_COUNT)
	#var total_point_chunk = _generate_points(data[0], data[1], data[2], data[3], data[4], data[5], data[6])
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	#_generate_mesh(total_point_chunk[1])
	
	#Layer 1:
	var baseTerrain = []
	for i in range(data[4].size()):
		if data[4][i] == 1:
			baseTerrain.append([data[2][i], biome_index[i], data[1][i]])
			
	#Layer 2:
	var coverTerrainExtents = []
	for i in range(data[4].size()):
		if data[4][i] == 2:
			coverTerrainExtents.append([data[2][i], biome_index[i], data[3][i], data[5][i], data[6][i], data[7][i], data[8][i], data[9][i], data[1][i]])
	
	var resourceExtents = []
	

	for i in range(data[4].size()):
		if data[4][i] == 3:
			resourceExtents.append([data[2][i], resource_index[i - biome_index.size()], data[3][i],  data[9][i], data[1][i]])
		
	
	var pointsList = _generate_points(coverTerrainExtents, resourceExtents)
	
	var coverTerrainPointsList = pointsList[0]
	var resourcePointsList = pointsList[1]
	map = _generate_mesh(baseTerrain, coverTerrainPointsList, resourcePointsList)
	
	if FLAG_VERBOSE: print("working?")
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	if FLAG_VERBOSE: print("Mesh generated: ", ellapsed)
	#_show_points(total_point_chunk[0])
	#point_chunk_print(total_point_chunk)
	if FLAG_VERBOSE: print("DONE!")

func _show_points(points: PackedVector3Array):
	for p in points:
		var instance = target.instantiate()
		instance.global_position = Vector2(p.x, p.y)
		instance.modulate = biome_index[p.z] * 0.9
		add_child(instance)

# 1 dimensional poisson disk distribution
func _poisson_dd_1d(interval_min: int, interval_max: int, n: int, density: float) -> Array:
	#var start_time = Time.get_ticks_usec()
	var interval_range: int = interval_max - interval_min
	var min_distance: float = ceil(interval_range / n) / density # The farthest each can get and still fit divided by density. If density >= 1, all can fit
	var chunk_count: int = int(interval_range / min_distance)
	 
	var p_points: PackedInt32Array
	var chunks: Array[Array] = [] # Each point is placed in a chunk. Each chunk is exactly min_distance wide starting from min (stretches to max)
	for c in chunk_count: # Initialize the array
		chunks.push_back([])
	
	for i in n: # For each point
		for attempt in max_poisson_attempts_1d: # Cap number of attempts in case to prevent infinite loop
			var sucess = true
			var x = randi_range(interval_min, interval_max)
			# Assign which chunk it is in
			var chunk_id = min(floor(x / min_distance),chunk_count-1)
			if (chunk_id > 0): # If it's not in the first chunk
				for p in chunks[chunk_id-1]: # Check for each point in the previous chunk
					if (abs(p - x) < min_distance):
						sucess = false # Then this point is too close to a previous point
						break
			if sucess: # If the point has failed, stop checking
				for p in chunks[chunk_id]: #Check for each point in this chunk
					if (abs(p - x) < min_distance):
						sucess = false
						break
			if (sucess and chunk_id < (chunk_count-1)): # If it's not in the next chunk
				for p in chunks[chunk_id+1]: #Check for each point in the previous chunk
					if (abs(p - x) < min_distance):
						sucess = false
						break
			if (sucess):
				chunks[chunk_id].push_back(x)
				p_points.push_back(x)
				break
			if (attempt == max_poisson_attempts_1d):
				if FLAG_VERBOSE: print("Biome Gen Timed out! 1d")
	return p_points


# 2 dimensional poisson disk distribution for rectangle - Generates based on resolution
# Takes previous points, generation options, and outputs a point
# top_left: Vector2i - The top left corner of the rectangle
# bottom_right: Vector2i - The bottom right corner of the rectangle
# min_distance: float - The minimum distance any two points can be
# density: float - How dense the points can be packed. Higher is denser, lower is less dense. < 1 may result in not fitting total points
# chunks: Array - A 2d array of chunks, each chunk is an array of points previously generated with tile coordinates
# Note: The diagonal of each chunk is equal to minimum_distance
func _poisson_dd_2d(top_left: Vector2i, bottom_right: Vector2i, min_distance: float, chunks: Array[Array], chunkLength: int) -> Vector2i:
	#var range_x: int = bottom_right.x - top_left.x
	#var range_y: int = bottom_right.y - top_left.y
	#if FLAG_VERBOSE: print(top_left)
	#if FLAG_VERBOSE: print(bottom_right)

	for attempt in max_poisson_attempts_2d: # Cap number of attempts in case to prevent infinite loop
		var sucess: bool = true
		var pointLocation: Vector2i = Vector2i(randi_range(top_left.x, bottom_right.x),randi_range(top_left.y, bottom_right.y))
		#var global_x = x + Vector2i(1, 1) * int(BORDER_RESOLUTION * PIXELS_PER_TILE)
		var chunk_index: Vector2i = Vector2i(int(pointLocation.x / chunkLength),int(pointLocation.y / chunkLength))
		for dx: int in range(-2,3):
			for dy: int in range(-2,3):
				var adj_chunk_index: Vector2i = chunk_index + Vector2i(dx,dy)
				if (adj_chunk_index.x >= 0 and adj_chunk_index.y >= 0) and (adj_chunk_index.x < chunks.size() and adj_chunk_index.y < chunks[0].size()): # CHECK FOR MAX BOUNDS!
					for point: Vector2 in chunks[adj_chunk_index.x][adj_chunk_index.y]:
						if Vector2i(point.x,point.y).distance_squared_to(pointLocation) < min_distance * min_distance:
							sucess = false
							break # Too close to a point
		if sucess:
			#if FLAG_VERBOSE: print(pointLocation)
			return pointLocation
	if FLAG_VERBOSE: print("PDD 2D Timed out!")
	return Vector2i.ZERO

#Data returned: min_distance, feature name, spawn area, occurences, layer, roughness, radius, number of points
func get_data() -> Array:
	#Resource data
	var json_received = gen_data.data
	var features = PackedStringArray()
	var spawn_area: Array # [0] is the top left, [1] is bottom right Vector2i
	var occurences: Array
	var layers: Array
	var roughness: Array
	var radius: Array # radius[i] is an array of integers of length roughness[i], where i is the ith feature
	var num_points: Array # num_points[i] is an array of integers of length roughness[i], where i is the ith feature
	var neighbourCounts: Array # an array of ints for the second layer terrain types random gen
	var minDistances: Array
	var gen_screen_resolution # The resolution that gen.json is balanced for
	
	# Initialize data from JSON
	gen_screen_resolution = Vector2(json_received["x-resolution"], json_received["y-resolution"])
	for feature in json_received["features"]:
		
		features.append(feature["name"])
		spawn_area.append(feature["spawn_area"])
		occurences.append(feature["occurences"])
		layers.append(feature["layer"])
		roughness.append(feature["roughness"])
		radius.append(feature["radius"])  # already an Array
		num_points.append(feature["num_points"])
		neighbourCounts.append(feature["neighbour_count"])  
		minDistances.append(feature["min_distance"])
		
		
	if FLAG_VERBOSE: print(features)
	if FLAG_VERBOSE: print(roughness)

	if FLAG_VERBOSE: print("")
	# Scaled based on desired resolution
	scalingFactor = Vector2((MAP_RESOLUTION.x - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE / gen_screen_resolution.x, (MAP_RESOLUTION.y - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE / gen_screen_resolution.y)
	var minScalingFactor
	if scalingFactor.x < scalingFactor.y:
		minScalingFactor = scalingFactor.x
	else:
		minScalingFactor = scalingFactor.y
	if FLAG_VERBOSE: print(radius)
	for r in radius:
		if FLAG_VERBOSE: print(r)
		if r != null:
			r[0] = r[0] * minScalingFactor
			r[1] = r[1] * minScalingFactor
			
	for m in minDistances:
		if m != null:
			m = m * minScalingFactor
	if FLAG_VERBOSE: print("BORDER: ")
	if FLAG_VERBOSE: print("(0, 0)")
	if FLAG_VERBOSE: print(MAP_RESOLUTION * PIXELS_PER_TILE)
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print("MAP AT: ")
	var mapRes = MAP_RESOLUTION
	mapRes.x -= BORDER_RESOLUTION
	mapRes.y -= BORDER_RESOLUTION
	var postBorderTopLeft = Vector2i(BORDER_RESOLUTION, BORDER_RESOLUTION)
	if FLAG_VERBOSE: print(postBorderTopLeft * PIXELS_PER_TILE)
	if FLAG_VERBOSE: print(mapRes * PIXELS_PER_TILE)
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print("SCALE FACTOR: " + str(scalingFactor))
	if FLAG_VERBOSE: print("")
	#for f in num_points.size():
		#for s in num_points[f].size():
		#	num_points[f][s] = int(num_points[f][s] * scalingFactor.length())
			

	for a in features.size():
		if FLAG_VERBOSE: print("BEEP BOOP: SCALING: " + features[a])
		for area in spawn_area[a]:
			
			if FLAG_VERBOSE: print("PRE-SCALED SPAWN AREA FOR: " + features[a] + ": ")
			if FLAG_VERBOSE: print(area[0][0])
			if FLAG_VERBOSE: print(area[0][1])
			if FLAG_VERBOSE: print(area[1][0])
			if FLAG_VERBOSE: print(area[1][1])
			
			area[0][0] = int(area[0][0] * scalingFactor.x) + BORDER_RESOLUTION * PIXELS_PER_TILE
			area[0][1] = int(area[0][1] * scalingFactor.y) + BORDER_RESOLUTION * PIXELS_PER_TILE
			
			area[1][0] = int(area[1][0] * scalingFactor.x) + BORDER_RESOLUTION * PIXELS_PER_TILE
			area[1][1] = int(area[1][1] * scalingFactor.y) + BORDER_RESOLUTION * PIXELS_PER_TILE
			
			if FLAG_VERBOSE: print("SCALED SPAWN AREA FOR " + features[a] + ": ")
			if FLAG_VERBOSE: print(area[0][0])
			if FLAG_VERBOSE: print(area[0][1])
			if FLAG_VERBOSE: print(area[1][0])
			if FLAG_VERBOSE: print(area[1][1])
			if FLAG_VERBOSE: print("")
	
	if FLAG_VERBOSE: print("DONE SCALING")
	#Calculate number of features
	var number_of_features = 0
	for f in features.size():
		number_of_features += occurences[f]
	#if FLAG_VERBOSE: print(number_of_features)
	var arrayToReturn = [sqrt((((MAP_RESOLUTION.x - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE) * ((MAP_RESOLUTION.y - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE)) / (number_of_features * PI * sphere_packing_constant)), features, spawn_area, occurences, layers, roughness, radius, num_points, neighbourCounts, minDistances]
	# Return min_distance, features, spawn_area, occurences, roughness, radius, num_points
	#if FLAG_VERBOSE: print(arrayToReturn)
	return arrayToReturn
	#return [sqrt((SCREEN_RESOLUTION.x * SCREEN_RESOLUTION.y) / (number_of_features * PI * sphere_packing_constant)), features, spawn_area, occurences, roughness, radius, num_points]
	
#Returns [PackedVector3Array, Array[Array], Vector2i]
func _generate_points(coverTerrain, resources) -> Array:
	var coverTerrainPointsList = []
	var resourcePointsList = []
	if FLAG_VERBOSE: print("GENERATE POINTS BEGIN: ")
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print(coverTerrain)
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print("GENREATE POINTS END")
	if FLAG_VERBOSE: print("")
	
	
	for type in coverTerrain:
		for bounding_area in type[0]:
			var chunkLen = type[7]
			var chunks: Array[Array]
			var chunk_count: Vector2i = Vector2i(int(ceil((bounding_area[1][0] - bounding_area[0][0]) / chunkLen)), int(ceil((bounding_area[1][1] - bounding_area[0][1]) / chunkLen)))

			for cx: int in chunk_count.x:
				chunks.push_back([])
				for cy: int in chunk_count.y:		
					chunks[cx].push_back([])
			
			for i in type[2]: #the number of occurences of the type
				
				
				var neighbourCount = randi_range(1, type[6])
				
				var topLeft = Vector2(bounding_area[0][0], bounding_area[0][1])
				var bottomRight = Vector2(bounding_area[1][0], bounding_area[1][1])
				
				var center = _poisson_dd_2d(topLeft, bottomRight, chunkLen, chunks, chunkLen)
				if FLAG_VERBOSE: print("")
				if FLAG_VERBOSE: print("GENERATING " + type[type.size() - 1] + " HERE: ")
				if FLAG_VERBOSE: print(center)
				if FLAG_VERBOSE: print("")
				
				var chunk_index = Vector2i(int(floor((center.x - topLeft.x) / chunkLen)),int(floor((center.y - topLeft.y) / chunkLen)))
				
				chunks[chunk_index.x][chunk_index.y].append(Vector2(center.x - topLeft.x, center.y - topLeft.y))
				var radius = randf_range(type[4][0], type[4][1])
				for j in neighbourCount:
					var offset = Vector2i(randi_range(-1 * radius, radius),  randi_range(-1 * radius, radius))
					var blob = generate_blob(center + offset, radius, type[5], type[3])
					if type[1] == 0:
						waterAreas.append(blob)
					coverTerrainPointsList.append([type[6], type[1], blob])
	
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print("WATER AREAS HERE:")
	if FLAG_VERBOSE: print(waterAreas)
	if FLAG_VERBOSE: print("")
	for r in resources:
		if FLAG_VERBOSE: print("")
		if FLAG_VERBOSE: print("GENERATING POINT FOR: ",r[4])
		if FLAG_VERBOSE: print("IN RANGE: ")
		if FLAG_VERBOSE: print(r[0])
		if FLAG_VERBOSE: print("")
		for bounding_area in r[0]:
			if r[3] != null:
				var chunkLen = r[3]
				var chunks: Array[Array]
				var chunk_count: Vector2i = Vector2i(int(ceil((bounding_area[1][0] - bounding_area[0][0]) / chunkLen)), int(ceil((bounding_area[1][1] - bounding_area[0][1]) / chunkLen)))

				for cx: int in chunk_count.x:
					chunks.push_back([])
					for cy: int in chunk_count.y:		
						chunks[cx].push_back([])
				
				for i in r[2]: #the number of occurences of the type
					
					var topLeft = Vector2(bounding_area[0][0], bounding_area[0][1])
					var bottomRight = Vector2(bounding_area[1][0], bounding_area[1][1])
					var center = null
					while center == null or point_in_water(center):
						center = _poisson_dd_2d(topLeft, bottomRight, chunkLen, chunks, chunkLen)
						center = grid.hex_center(center)
					
					#var x_offset = null
					#var y_offset = null
					#if center.x <= ((bounding_area[1][0] - bounding_area[0][0])/ 2):
						#x_offset = RESOURCE_WATER_OFFSET
					#else:
						#x_offset = -1 * RESOURCE_WATER_OFFSET
						#
					#if center.y <= ((bounding_area[1][1] - bounding_area[0][1]) / 2):
						#y_offset = RESOURCE_WATER_OFFSET
					#else:
						#y_offset = -1 * RESOURCE_WATER_OFFSET
							#
					#while point_in_water(center):
						#if FLAG_VERBOSE: print("")
						#if FLAG_VERBOSE: print("ADJUSTING FOR WATER HERE: ")
						#if FLAG_VERBOSE: print(center)
						#if FLAG_VERBOSE: print("")
						#center.x += x_offset
						#center.y += y_offset
						#if FLAG_VERBOSE: print("NOW HERE: ")
						#if FLAG_VERBOSE: print(center)
						#if FLAG_VERBOSE: print("")
							#
				
					
					if FLAG_VERBOSE: print("")
					if FLAG_VERBOSE: print("GENERATING " + r[r.size() - 1] + " HERE: ")
					if FLAG_VERBOSE: print(center)
					if FLAG_VERBOSE: print("")
					
					var chunk_index = Vector2i(int(floor((center.x - topLeft.x) / chunkLen)),int(floor((center.y - topLeft.y) / chunkLen)))
					
					if chunk_index.x >= chunks.size():
						chunk_index.x = chunks.size() - 1
					if chunk_index.y >= chunks[chunk_index.x].size():
						chunk_index.y = chunks[chunk_index.x].size() - 1
					chunks[chunk_index.x][chunk_index.y].append(Vector2(center.x - topLeft.x, center.y - topLeft.y))
					
					if center.x <= 0 or center.y <= 0:
						center = Vector2(0,0)
						while center.x == 0 or point_in_water(center):
							center.x = randi_range(bounding_area[0][0],bounding_area[1][0])
							center.y = randi_range(bounding_area[0][1],bounding_area[1][1])
					resourcePointsList.append([r[1], center])
			else:
				var center = Vector2(0,0)
				while center.x == 0 or point_in_water(center):
					center.x = randi_range(bounding_area[0][0],bounding_area[1][0])
					center.y = randi_range(bounding_area[0][1],bounding_area[1][1])
				#var x_offset = null
				#var y_offset = null
				
				#if center.x <= ((bounding_area[1][0] - bounding_area[0][0])/ 2):
					#x_offset = RESOURCE_WATER_OFFSET
				#else:
					#x_offset = -1 * RESOURCE_WATER_OFFSET
					#
				#if center.y <= ((bounding_area[1][1] - bounding_area[0][1]) / 2):
					#y_offset = RESOURCE_WATER_OFFSET
				#else:
					#y_offset = -1 * RESOURCE_WATER_OFFSET
						#
				#while point_in_water(center):
					#if FLAG_VERBOSE: print("")
					#if FLAG_VERBOSE: print("ADJUSTING FOR WATER HERE: ")
					#if FLAG_VERBOSE: print(center)
					#if FLAG_VERBOSE: print("")
					#center.x += x_offset
					#center.y += y_offset
					#if FLAG_VERBOSE: print("NOW HERE: ")
					#if FLAG_VERBOSE: print(center)
					#if FLAG_VERBOSE: print("")
				
				center = grid.hex_center(center)
				resourcePointsList.append([r[1], center])
	if FLAG_VERBOSE: print("")
	
	var unplaced = 0
	for r in resourcePointsList:
		if r[1].x < 0:
			print("UNPLACED: " + str(r[0]))
			unplaced += 1
			
	if FLAG_VERBOSE: print("CHECKING FOR UNPLACED RESOURCES: " + str(unplaced))
	if FLAG_VERBOSE: print("")
	return [coverTerrainPointsList, resourcePointsList]
	
"""
	var points = PackedVector3Array() # (x, y, feature index)
		
	# Points and chunks
	#var min_distance: float = sqrt((SCREEN_RESOLUTION.x * SCREEN_RESOLUTION.y) / (number_of_features * PI * sphere_packing_constant)) # The minimum distance any two points can be
	var chunks: Array[Array] # Each point is placed in a chunk. Each chunk is exactly min_distance_x wide starting from min (stretches to max)

	#var chunk_count: Vector2i = Vector2i(int(ceil((MAP_RESOLUTION.x * PIXELS_PER_TILE) / GLOBAL_chunk_length)), int(ceil((MAP_RESOLUTION.y * PIXELS_PER_TILE) / GLOBAL_chunk_length)))
	
	# Initialize the chunks array
	
	for cx: int in GLOBAL_CHUNK_COUNT.x:
		chunks.push_back([])
		for cy: int in GLOBAL_CHUNK_COUNT.y:
			
			chunks[cx].push_back([])

	for f in features.size(): #for each terrain type
		var top_left: Vector2i = Vector2i(spawn_area[f][0][0], spawn_area[f][0][1])
		var bottom_right: Vector2i = Vector2i(spawn_area[f][1][0], spawn_area[f][1][1])
		for occ in occurences[f]:
			var global_point: Vector2i = _poisson_dd_2d(top_left, bottom_right, min_distance, chunks)
			#var global_point = point + Vector2i(BORDER_RESOLUTION * PIXELS_PER_TILE, PIXELS_PER_TILE * BORDER_RESOLUTION)# Shift by the border
			# Put occurence in points and in chunks
			points.append(Vector3(global_point.x, global_point.y, f))
			var chunk_index = Vector2i(int(floor(global_point.x / GLOBAL_chunk_length)),int(floor(global_point.y / GLOBAL_chunk_length)))
			chunks[chunk_index.x][chunk_index.y].append(Vector3(global_point.x, global_point.y, f))
			# Stack of [position, depth]
			var stack: Array = [[global_point, 0]]
			
	
			while stack.size() > 0:
				var item = stack.pop_back()
				var center = item[0]
				var depth = item[1]
				# Stop if we've reached max depth
				if depth >= roughness[f]:
					continue
				var num_children = radius[f][depth]
				
				var radius = num_points[f][depth]
				var angles = _poisson_dd_1d(0, floor(TAU*1000),num_children,1) # Multiplied by 1000 to be like an integer
				
				for a in angles:
					# Random angle around the circle
					var offset = Vector2(radius, 0).rotated(a / 1000.)
					
					var new_point = Vector2(center.x,center.y) + offset
					#new_point.x = int(clamp(new_point.x, 2./3. * BORDER_RESOLUTION, 1000000))#MAP_RESOLUTION.x))
					#new_point.y = int(clamp(new_point.y, 2./3. * BORDER_RESOLUTION, MAP_RESOLUTION.y - 2./3. * BORDER_RESOLUTION))
					if ((BORDER_RESOLUTION * PIXELS_PER_TILE) < new_point.x and new_point.x < (MAP_RESOLUTION.x * PIXELS_PER_TILE) - (BORDER_RESOLUTION * PIXELS_PER_TILE) and 
						((BORDER_RESOLUTION * PIXELS_PER_TILE) < new_point.y and new_point.y < (MAP_RESOLUTION.y * PIXELS_PER_TILE) - (PIXELS_PER_TILE* BORDER_RESOLUTION))):

						points.append(Vector3(new_point.x, new_point.y, f))
						var new_chunk_index = Vector2i(int(new_point.x / GLOBAL_chunk_length),int(new_point.y / GLOBAL_chunk_length))
						chunks[chunk_index.x][chunk_index.y].append(Vector3(new_point.x, new_point.y, f))
						# Queue it up for the next depth layer
						depth += 1
						stack.append([new_point, depth])
				
				
	if FLAG_VERBOSE: print(points.size())
	return [points, chunks]
"""

# Generates the mesh
func _generate_mesh(baseTerrain: Array, coverTerrain: Array, resources: Array): # 

	# Mesh variables
	var mesh = ArrayMesh.new()
	var arrays = []
	var quad_size: int = PIXELS_PER_TILE
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	var generatingMap = []
	#if FLAG_VERBOSE: print(baseTerrain)
	# Generates mesh
	if FLAG_VERBOSE: print("BASE TERRAINS: ")
	for type in baseTerrain:
		if FLAG_VERBOSE: print(type)
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print("COVER TERRAINS: ")
	for blob in coverTerrain:
		if FLAG_VERBOSE: print(blob)
		
	#Base Terrain coverage
	for row: int in MAP_RESOLUTION.y:
		var rowToAppend = []
		for col: int in MAP_RESOLUTION.x:
			var x: int = col * quad_size + terrainOffset
			var y: int = row * quad_size
			
			#var i = vertices.size()  # index of first vertex in this quad
			

			

			#Hard sets quads to ocean
			if col < (BORDER_RESOLUTION - BEACH_RESOLUTION) or row < BORDER_RESOLUTION - BEACH_RESOLUTION or col > (MAP_RESOLUTION.x - (BORDER_RESOLUTION) + BEACH_RESOLUTION) or row > (MAP_RESOLUTION.y - BORDER_RESOLUTION + BEACH_RESOLUTION):
				
				var color = 2 #WATER
				#colors.append_array([color, color, color, color])
				rowToAppend.append(color)
				# Define two triangles (quad = 2 triangles)
				#indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
				continue
				
			#Hard sets quads to beach
			if col <= (BORDER_RESOLUTION) or row <= BORDER_RESOLUTION or col >= (MAP_RESOLUTION.x - (BORDER_RESOLUTION)) or row >= (MAP_RESOLUTION.y - BORDER_RESOLUTION):
				
				var color = 3 #DESERT/Sand -> Needs change3z
				#colors.append_array([color, color, color, color])
				# Define two triangles (quad = 2 triangles)
				#indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
				rowToAppend.append(color)
				continue
			var found = false
			for type in baseTerrain:
				
				var IN = false
				for area in type[0]:
					if col * PIXELS_PER_TILE >= area[0][0] and col * PIXELS_PER_TILE <= area[1][0]:
						if row * PIXELS_PER_TILE >= area[0][1] and row * PIXELS_PER_TILE <= area[1][1]:
							IN = true
				if IN:
					rowToAppend.append(type[1])
					
					#colors.append_array([type[1],type[1],type[1],type[1]])
					#indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
					found = true
					break
	
			if found == false:
				var color = biome_index[0]
				
				#colors.append_array([color, color, color, color])
				#indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
				rowToAppend.append(color)
		generatingMap.append(rowToAppend)
	#Cover Terrain coverage
	
	for blob in coverTerrain:
		if FLAG_VERBOSE: print("Its blobbin' time")
		var min_x = INF; var max_x = -INF
		var min_y = INF; var max_y = -INF
		for p in blob[2]:
			min_x = min(min_x, p.x); max_x = max(max_x, p.x)
			min_y = min(min_y, p.y); max_y = max(max_y, p.y)
		
		var col_start = int(min_x / PIXELS_PER_TILE)
		var col_end   = int(max_x / PIXELS_PER_TILE)
		var row_start = int(min_y / PIXELS_PER_TILE)
		var row_end   = int(max_y / PIXELS_PER_TILE)
		
		if col_start < BORDER_RESOLUTION: col_start = BORDER_RESOLUTION + 1
		if col_end > MAP_RESOLUTION.x - BORDER_RESOLUTION: col_end = MAP_RESOLUTION.x - BORDER_RESOLUTION
		if row_start < BORDER_RESOLUTION: row_start = BORDER_RESOLUTION + 1
		if row_end > MAP_RESOLUTION.y - BORDER_RESOLUTION: row_end = MAP_RESOLUTION.y - BORDER_RESOLUTION
		
		
		for row in range(row_start, row_end):
			for col in range(col_start, col_end):
				var cell_center = Vector2(
					col * PIXELS_PER_TILE + PIXELS_PER_TILE * 0.5,
					row * PIXELS_PER_TILE + PIXELS_PER_TILE * 0.5
				)
				if point_in_polygon(cell_center, blob[2]):
					
					generatingMap[row][col] = blob[1]
					
					"""
					var base_idx = (row * MAP_RESOLUTION.x + col) * 4
					# Set all 4 corners of the quad to forest color
					colors[base_idx + 0] = blob[1] # top-left
					colors[base_idx + 1] = blob[1]  # top-right
					colors[base_idx + 2] = blob[1]  # bottom-left
					colors[base_idx + 3] = blob[1]  # bottom-right
					"""
	
	generatingMap = roughenMap(generatingMap)
	
	
	#Resource management
	for r in resources:
		var rX = floor((r[1][0]) / PIXELS_PER_TILE)
		var rY = floor((r[1][1]) / PIXELS_PER_TILE)
		#
		var quad = null
		
		if rX <= (MAP_RESOLUTION.x / 2) / 2 or (rX >= (MAP_RESOLUTION.x / 2) and rX <= (MAP_RESOLUTION.x * 3/4)):
			quad = RESOURCE_WATER_OFFSET
		else:
			quad = -1 * RESOURCE_WATER_OFFSET
		if rY <= MAP_RESOLUTION.y / 2 :
			quad = RESOURCE_WATER_OFFSET
		else:
			quad = -1 * RESOURCE_WATER_OFFSET
		var surroundingWater = 3
		
		while surroundingWater >= 2: # ADD A PUSHING SIMILAR TO THIS FOR BIOME SPECIFIC RESOURCES
			surroundingWater = 0
			if generatingMap[rY + 1][rX + 1] == 2: #2: WATER
				surroundingWater += 1
			if generatingMap[rY + 1][rX - 1] == 2:
				surroundingWater += 1
			if generatingMap[rY - 1][rX + 1] == 2:
				surroundingWater += 1
			if generatingMap[rY - 1][rX - 1] == 2:
				surroundingWater += 1
			if FLAG_VERBOSE: print("")
			if FLAG_VERBOSE: print("RESOURCE AT: ")
			if FLAG_VERBOSE: print(str(rX) + ", " + str(rY))
			if FLAG_VERBOSE: print("HAS " + str(surroundingWater) + " PIXELS")
			
			if surroundingWater >= 2:
				rX += quad
				rY += quad
				if FLAG_VERBOSE: print("ADJUSTING ACCORDINGLY")
		
		generatingMap[rY][rX] = r[0] #Setting to the resource ID
		
	#For debugging the grid
	for row: int in MAP_RESOLUTION.y:
		for col: int in MAP_RESOLUTION.x:
			var i = vertices.size()  # index of first vertex in this quad
			var x: int = col * PIXELS_PER_TILE + terrainOffset
			var y: int = row * PIXELS_PER_TILE
			
			# Define the 4 vertices of the quad (clockwise or CCW)
			vertices.push_back(Vector2(x, y))
			vertices.push_back(Vector2(x + quad_size, y))
			vertices.push_back(Vector2(x + quad_size, y + quad_size))
			vertices.push_back(Vector2(x, y + quad_size))
			
			
			var biome = generatingMap[row][col]
			var color = null
			#[Forest, Tundra, Water, Sand, rainforest, Plains, Grassland]
			if biome == 0:
				color = Color.FOREST_GREEN
			if biome == 1:
				color = Color.SKY_BLUE
			if biome == 2:
				color = Color.ROYAL_BLUE
			if biome == 3:
				color = Color.SANDY_BROWN
			if biome == 4:
				color = Color.GREEN_YELLOW
			if biome == 5:
				color = Color.LIGHT_GREEN
			if biome == 6:
				color = Color.WHEAT
			colors.append_array([color, color, color, color])
			indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
	
			
	if FLAG_VERBOSE: print("")
	if FLAG_VERBOSE: print("There should be about: " + str(MAP_RESOLUTION.x * MAP_RESOLUTION.y) + " quads")
	if FLAG_VERBOSE: print("There are: " + str(colors.size()) + " quads")
	
	
	# Index of a quad should be: ((row - 1) * map_resolution.x) + col
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if debuggingGrid:
		$"Ground Mesh".mesh = mesh
	
	return generatingMap

func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside = false
	var n = polygon.size()
	var j = n - 1
	for i in n:
		var xi = polygon[i].x; var yi = polygon[i].y
		var xj = polygon[j].x; var yj = polygon[j].y
		if ((yi > point.y) != (yj > point.y)) and \
		(point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi):
			inside = !inside
		j = i
	return inside
	
	
func generate_blob(center: Vector2, base_radius: float, num_points: int, roughness: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var n = num_points + randi_range(-1 * RANDOM_BLOB_VARIATION, RANDOM_BLOB_VARIATION)  # slight variation in point count
	for i in n:
		var angle = (float(i) / n) * TAU
		var new_base_radius = base_radius
		if i != 0:
			new_base_radius = (base_radius + (pts[i - 1]-center).length()) / 2
		var r = new_base_radius * (1.0 + randf_range(-roughness, roughness))
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	return pts


func roughenMap(base_map: Array) -> Array:
	if FLAG_VERBOSE: print("base_map border sample: ", base_map[0][0], " ", base_map[0][1], " ", base_map[1][0])
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = warp_frequency
	noise.fractal_octaves = 3

	var result = []
	var actual_width = base_map[0].size()
	var actual_height = base_map.size()
	var warp_padding = warp_strength + 1
	var inner_x_min = BORDER_RESOLUTION + warp_padding
	var inner_x_max = actual_width - BORDER_RESOLUTION - warp_padding - 1
	var inner_y_min = BORDER_RESOLUTION + warp_padding
	var inner_y_max = actual_height - BORDER_RESOLUTION - warp_padding - 1
	if FLAG_VERBOSE: print("actual_width: ", actual_width)
	if FLAG_VERBOSE: print("actual_height: ", actual_height)
	if FLAG_VERBOSE: print("BORDER_RESOLUTION: ", BORDER_RESOLUTION)
	if FLAG_VERBOSE: print("inner_x_min: ", inner_x_min, " inner_x_max: ", inner_x_max)
	if FLAG_VERBOSE: print("inner_y_min: ", inner_y_min, " inner_y_max: ", inner_y_max)
	for y in actual_height:
		result.append([])
		for x in actual_width:
			
			if x < BORDER_RESOLUTION or x >= actual_width - BORDER_RESOLUTION or y < BORDER_RESOLUTION or y >= actual_height - BORDER_RESOLUTION:
				result[y].append(base_map[y][x])
				continue

			var warp_x = noise.get_noise_2d(x, y) * warp_strength
			var warp_y = noise.get_noise_2d(x + noise_offset, y + noise_offset) * warp_strength

			var sample_x = clamp(floori(x + warp_x), inner_x_min, inner_x_max)
			var sample_y = clamp(floori(y + warp_y), inner_y_min, inner_y_max)
			
			while base_map[sample_y][sample_x] in resource_index:
				print("AHHHH")
			result[y].append(base_map[sample_y][sample_x])
	if FLAG_VERBOSE: print("result border sample: ", result[0][0], " ", result[0][1], " ", result[1][0])
	return result

func getPixelsPerTile() -> int:
	return PIXELS_PER_TILE
	
func point_in_water(point): 
	for w in waterAreas:
		if point_in_polygon(point, w):
			return true
	return false
