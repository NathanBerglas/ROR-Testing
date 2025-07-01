extends Node2D

# Main Area
@export var SCREEN_RESOLUTION: Vector2i = Vector2i(1920,1080)
@export var COLS: int = 192
var PIXELS_PER_TILE: int

# Map Area
@export var BORDER_RESOLUTION: int = 500
var MAP_RESOLUTION: Vector2i
var MAP_COLS: int
var MAP_ROWS: int

# Gen Data
@export var gen_data: JSON

# Poisson distribution constants
const max_poisson_attempts_1d: int = 100
const max_poisson_attempts_2d: int = 100
const sphere_packing_constant: float = 0.8

func _ready() -> void:
	# Main Area
	PIXELS_PER_TILE = int(SCREEN_RESOLUTION.x / COLS)

	# Map Area
	MAP_RESOLUTION = Vector2i(SCREEN_RESOLUTION.x + BORDER_RESOLUTION, SCREEN_RESOLUTION.y + BORDER_RESOLUTION)
	MAP_COLS = MAP_RESOLUTION.x / PIXELS_PER_TILE
	MAP_ROWS = MAP_RESOLUTION.y / PIXELS_PER_TILE
	
	# Generate Mesh
	_generate_mesh()

# 1 dimensional poisson disk distribution
func _poisson_dd_1d(min: int, max: int, n: int, density: float) -> Array:
	var start_time = Time.get_ticks_usec()
	var range: int = max-min
	var min_distance: float = ceil(range / n) / density # The farthest each can get and still fit divided by density. If density >= 1, all can fit
	var chunk_count: int = int(range / min_distance)
	 
	var points: PackedInt32Array
	var chunks: Array[Array] = [] # Each point is placed in a chunk. Each chunk is exactly min_distance wide starting from min (stretches to max)
	for c in chunk_count: # Initialize the array
		chunks.push_back([])
	
	for i in n: # For each point
		for attempt in max_poisson_attempts_1d: # Cap number of attempts in case to prevent infinite loop
			var sucess = true
			var x = randi_range(min, max)
			# Assign which chunk it is in
			var chunk_id = min(floor(x / min_distance),chunk_count-1) # To not overrun 
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
				points.push_back(x)
				break
			if (attempt == max_poisson_attempts_1d):
				print("Biome Gen Timed out! 1d")
	#print(Time.get_ticks_usec() - start_time, " microseconds passed") # Debugging
	return points

# 2 dimensional poisson disk distribution for rectangle - Generates based on resolution
# Takes previous points, generation options, and outputs a point
# top_left: Vector2i - The top left corner of the rectangle
# bottom_right: Vector2i - The bottom right corner of the rectangle
# min_distance: float - The minimum distance any two points can be
# density: float - How dense the points can be packed. Higher is denser, lower is less dense. < 1 may result in not fitting total points
# chunks: Array - A 2d array of chunks, each chunk is an array of points previously generated with tile coordinates
# Note: The diagonal of each chunk is equal to minimum_distance
func _poisson_dd_2d(top_left: Vector2i, bottom_right: Vector2i, min_distance: float, chunks: Array[Array]) -> Vector2i:
	var range_x: int = bottom_right.x - top_left.x
	var range_y: int = bottom_right.y - top_left.y
	var chunk_length: float = 0.70711 * min_distance # sqrt(2) * min_distance

	for attempt in max_poisson_attempts_2d: # Cap number of attempts in case to prevent infinite loop
		var sucess: bool = true
		var x: Vector2i = Vector2i(randi_range(top_left.x, bottom_right.x),randi_range(top_left.y, bottom_right.y))
		var global_x = x + Vector2i(1, 1) * int(BORDER_RESOLUTION/2)
		var chunk_index: Vector2i = Vector2i(int(global_x.x / chunk_length),int(global_x.y / chunk_length))
		for dx: int in range(-2,3):
			for dy: int in range(-2,3):
				var adj_chunk_index: Vector2i = chunk_index + Vector2i(dx,dy)
				if (adj_chunk_index.x >= 0 and adj_chunk_index.y >= 0) and (adj_chunk_index.x >= chunks.size() and adj_chunk_index.y >= chunks[0].size()): # CHECK FOR MAX BOUNDS!
					for point: Vector2i in chunks[adj_chunk_index.x][adj_chunk_index.y]:
						if point.distance_squared_to(x) < min_distance * min_distance:
							sucess = false
							break # Too close to a point
		if sucess:
			return x
	print("PDD 2D Timed out!")
	return Vector2i.ZERO

func _ocean(distance: int) -> Vector2:
	var shore_length: int = MAP_RESOLUTION.x * 2 + MAP_RESOLUTION.y
	distance *= shore_length / 100
	if (distance > MAP_RESOLUTION.x):
		distance -= MAP_RESOLUTION.x
		if (distance > MAP_RESOLUTION.y):
			distance -= MAP_RESOLUTION.y
			return Vector2(distance,MAP_RESOLUTION.y)
		return Vector2(0,distance)
	return Vector2(distance,0)

# Generates the mesh
func _generate_mesh():
	# Mesh variables
	var mesh = ArrayMesh.new()
	var arrays = []
	var quad_size: int = PIXELS_PER_TILE
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	#Resource data
	var json_received = gen_data.data
	var features = PackedStringArray()
	var spawn_area: Array # [0] is the top left, [1] is bottom right Vector2i
	var occurences = PackedInt32Array()
	var gen_depth = PackedInt32Array()
	var sub_occurences: Array # sub_occurences[i] is an array of integers of length gen_depth[i], where i is the ith feature
	var sizes: Array # sizes[i] is an array of integers of length gen_depth[i], where i is the ith feature
	var gen_screen_resolution # The resolution that gen.json is balanced for
	
	# Initialize data from JSON
	gen_screen_resolution = Vector2(json_received["x-resolution"], json_received["y-resolution"])
	for feature in json_received["features"]:
		features.append(feature["name"])
		spawn_area.append(feature["spawn_area"])
		occurences.append(feature["occurences"])
		gen_depth.append(feature["gen_depth"])
		sub_occurences.append(feature["sub_occurences"])  # already an Array
		sizes.append(feature["sizes"])  # already an Array
	
	# Scaled based on desired resolution
	var scaling_factor = (SCREEN_RESOLUTION.length() / gen_screen_resolution.length())
	for f in sizes.size():
		for s in sizes[f].size():
			sizes[f][s] = int(sizes[f][s] * scaling_factor)
	for a in spawn_area.size():
		for p in 2:
			for xy in 2:
				spawn_area[a][p][xy] = int(spawn_area[a][p][xy] * scaling_factor)
	
	#Calculate number of features
	var number_of_features = 0
	for f in features.size():
		number_of_features += occurences[f]
		
	# Points and chunks
	var points = PackedVector3Array() # (x, y, feature index)
	var min_distance: float = sqrt((SCREEN_RESOLUTION.x * SCREEN_RESOLUTION.y) / (number_of_features * PI * sphere_packing_constant)) # The minimum distance any two points can be
	var chunks: Array[Array] # Each point is placed in a chunk. Each chunk is exactly min_distance_x wide starting from min (stretches to max)
	var chunk_length: float = 0.70711 * min_distance # sqrt(2) * min_distance
	var chunk_count: Vector2i = Vector2i(int(ceil(MAP_RESOLUTION.x / chunk_length)), int(ceil(MAP_RESOLUTION.y / chunk_length)))
	
	# Initialize the chunks array
	for cx: int in chunk_count.x:
		chunks.push_back([])
		for cy: int in chunk_count.y:
			chunks[cx].push_back([])

	for f in features.size():
		for occ in occurences[f]:
			var top_left: Vector2i = Vector2i(spawn_area[f][0][0], spawn_area[f][0][1])
			var bottom_right: Vector2i = Vector2i(spawn_area[f][1][0], spawn_area[f][1][1])
			var point: Vector2i = _poisson_dd_2d(top_left, bottom_right, min_distance, chunks)
			point += Vector2i(1, 1) * int(BORDER_RESOLUTION/2) # Shift by the border
			# Put occurence in points and in chunks
			points.append(Vector3(point.x, point.y, f))
			chunks[int(point.x / chunk_length)][int(point.y / min_distance)].push_back(point)
			# Stack of [position, depth]
			var stack: Array = [[point, 0]]
			while stack.size() > 0:
				var item = stack.pop_back()
				var center = item[0]
				var depth = item[1]
				# Stop if we've reached max depth
				if depth >= gen_depth[f]:
					continue
				var num_children = sub_occurences[f][depth]
				var radius = sizes[f][depth]
				var angles = _poisson_dd_1d(0, floor(TAU*1000),num_children,1) # Multiplied by 1000 to be like an integer
				
				for a in angles:
					# Random angle around the circle
					var offset = Vector2(radius, 0).rotated(a / 1000.)
					var new_point_f = Vector2(center.x,center.y) + offset
					var new_point = Vector2i(floor(new_point_f.x),floor(new_point_f.y))
					points.append(Vector3(round(new_point.x), round(new_point.y), f))
					# Queue it up for the next depth layer
					depth += 1
					stack.append([new_point, depth])

	# Place the Ocean
	var ocean_distances: Array = range(0,BORDER_RESOLUTION/3,1)
	for p in ocean_distances.size():
		var ocean_point: Vector2 = _ocean(ocean_distances[p])
		points.push_back(Vector3(ocean_point.x, ocean_point.y, -1))
		
	# Generates mesh
	for row: int in MAP_ROWS:
		for col: int in MAP_COLS:
			var x: int = col * quad_size
			var y: int = row * quad_size
			
			var i = vertices.size()  # index of first vertex in this quad
			
			# Define the 4 vertices of the quad (clockwise or CCW)
			vertices.push_back(Vector2(x, y))
			vertices.push_back(Vector2(x + quad_size, y))
			vertices.push_back(Vector2(x + quad_size, y + quad_size))
			vertices.push_back(Vector2(x, y + quad_size))
			
			# Calculate the closest feature to this point
			var closest_feature = Vector2(-1, -1) # distance squared, feature id
			for p in points:
				var distance = (col * PIXELS_PER_TILE - p.x) * (col * PIXELS_PER_TILE - p.x) + (row * PIXELS_PER_TILE - p.y) * (row * PIXELS_PER_TILE - p.y) # Calculate distance squared
				if ((closest_feature.x == -1) or (distance < closest_feature.x)): # New closest feature
					closest_feature = Vector2(distance,p.z) 
			
			# Generate the color for the whole quad
			var color = Color.WHITE
			if (closest_feature.y == 0): # Origin
				color = Color.BLACK
			elif (closest_feature.y == 1): # Rainforest
				color = Color.GREEN_YELLOW
			elif (closest_feature.y == 2): # Tundra
				color = Color.SKY_BLUE
			elif (closest_feature.y == 3): # Desert
				color = Color.SANDY_BROWN
			elif (closest_feature.y == 4): # Forest
				color = Color.FOREST_GREEN
			elif (closest_feature.y == 5): # Plains
				color = Color.LIGHT_GREEN
			elif (closest_feature.y == 6): # Lake
				color = Color.ROYAL_BLUE
			elif (closest_feature.y == -1): # Ocean
				color = Color.DARK_BLUE
				
			# FOR DEBUGGING
			#if (row == floor(MAP_ROWS/2) and col == floor(MAP_COLS/2)):
			#	color = Color.WEB_PURPLE
			#if (closest_feature.x < PIXELS_PER_TILE): # Is on a point
			#	color = Color.WEB_PURPLE
			
			colors.append_array([color, color, color, color])
			# Define two triangles (quad = 2 triangles)
			indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])

	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$"Ground Mesh".mesh = mesh
