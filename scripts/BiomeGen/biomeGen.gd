extends Node2D

# Main Area
#@export var SCREEN_RESOLUTION: Vector2i = Vector2i(1920,1080)
#@export var COLS: int = 192
#var PIXELS_PER_TILE: int

# Map Area
@export var BORDER_RESOLUTION: int = 10
@export var PIXELS_PER_TILE: int = 10
var MAP_RESOLUTION: Vector2i = Vector2i(210, 110)

# Gen Data
@export var gen_data: JSON

#Hardcode
@export var origin_radius = 10*10 # Squared
@export var biome_colours: Array[Color] = [Color.BLACK, Color.FOREST_GREEN, Color.GREEN_YELLOW, Color.SKY_BLUE, Color.SANDY_BROWN, Color.WHEAT, Color.FOREST_GREEN, Color.LIGHT_GREEN, Color.ROYAL_BLUE]

# Debugging
@export var target: PackedScene

# Poisson distribution constants
const max_poisson_attempts_1d: int = 100
const max_poisson_attempts_2d: int = 300
const sphere_packing_constant: float = 0.9069
var GLOBAL_CHUNK_COUNT = Vector2i()
var GLOBAL_chunk_length = float()
func point_chunk_print(point_chunk) -> void:
	var chunk_array = point_chunk[1]
	var chunk_dim = GLOBAL_CHUNK_COUNT
	for col in chunk_dim[0]:
		for row in chunk_dim[1]:
			print("Chunk (",col, ", ", row, ")")
			print(chunk_array[col-1][row-1])
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
	var data = get_data()
	#Data: min_distance, features, spawn_area, occurences, gen_depth, sub_occurences, sizes
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	GLOBAL_chunk_length = data[0] * 0.70711 # min_distance / sqrt(2)
	print("Data gotten: ", ellapsed)
	print(GLOBAL_chunk_length)
	GLOBAL_CHUNK_COUNT = Vector2i(int(ceil((MAP_RESOLUTION.x - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE / GLOBAL_chunk_length)), int(ceil((MAP_RESOLUTION.y - BORDER_RESOLUTION * 2)  * PIXELS_PER_TILE / GLOBAL_chunk_length)))
	print(GLOBAL_CHUNK_COUNT)
	#var total_point_chunk = _generate_points(data[0], data[1], data[2], data[3], data[4], data[5], data[6])
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	#_generate_mesh(total_point_chunk[1])
	var baseTerrain = []
	
	for i in range(data[4].size()):
		if data[4][i] == 1:
			baseTerrain.append([data[2][i], biome_colours[i]])
	_generate_mesh(baseTerrain)
	print("working?")
	ellapsed = Time.get_ticks_msec() - previous_time
	previous_time = Time.get_ticks_msec()
	print("Mesh generated: ", ellapsed)
	#_show_points(total_point_chunk[0])
	#point_chunk_print(total_point_chunk)
	print("DONE!")

func _show_points(points: PackedVector3Array):
	for p in points:
		var instance = target.instantiate()
		instance.global_position = Vector2(p.x, p.y)
		instance.modulate = biome_colours[p.z] * 0.9
		add_child(instance)

# 1 dimensional poisson disk distribution
func _poisson_dd_1d(min: int, max: int, n: int, density: float) -> Array:
	var start_time = Time.get_ticks_usec()
	var range: int = max-min
	var min_distance: float = ceil(range / n) / density # The farthest each can get and still fit divided by density. If density >= 1, all can fit
	var chunk_count: int = int(range / min_distance)
	 
	var p_points: PackedInt32Array
	var chunks: Array[Array] = [] # Each point is placed in a chunk. Each chunk is exactly min_distance wide starting from min (stretches to max)
	for c in chunk_count: # Initialize the array
		chunks.push_back([])
	
	for i in n: # For each point
		for attempt in max_poisson_attempts_1d: # Cap number of attempts in case to prevent infinite loop
			var sucess = true
			var x = randi_range(min, max)
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
				print("Biome Gen Timed out! 1d")
	return p_points


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
	print(top_left)
	print(bottom_right)

	for attempt in max_poisson_attempts_2d: # Cap number of attempts in case to prevent infinite loop
		var sucess: bool = true
		var pointLocation: Vector2i = Vector2i(randi_range(top_left.x, bottom_right.x),randi_range(top_left.y, bottom_right.y))
		#var global_x = x + Vector2i(1, 1) * int(BORDER_RESOLUTION * PIXELS_PER_TILE)
		var chunk_index: Vector2i = Vector2i(int(pointLocation.x / GLOBAL_chunk_length),int(pointLocation.y / GLOBAL_chunk_length))
		for dx: int in range(-2,3):
			for dy: int in range(-2,3):
				var adj_chunk_index: Vector2i = chunk_index + Vector2i(dx,dy)
				if (adj_chunk_index.x >= 0 and adj_chunk_index.y >= 0) and (adj_chunk_index.x < chunks.size() and adj_chunk_index.y < chunks[0].size()): # CHECK FOR MAX BOUNDS!
					for point: Vector3 in chunks[adj_chunk_index.x][adj_chunk_index.y]:
						if Vector2i(point.x,point.y).distance_squared_to(pointLocation) < min_distance * min_distance:
							sucess = false
							break # Too close to a point
		if sucess:
			print(pointLocation)
			return pointLocation
	print("PDD 2D Timed out!")
	return Vector2i.ZERO

func get_data() -> Array:
	#Resource data
	var json_received = gen_data.data
	var features = PackedStringArray()
	var spawn_area: Array # [0] is the top left, [1] is bottom right Vector2i
	var occurences = PackedInt32Array()
	var layers = PackedInt32Array()
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
		layers.append(feature["layer"])
		gen_depth.append(feature["gen_depth"])
		sub_occurences.append(feature["sub_occurences"])  # already an Array
		sizes.append(feature["sizes"])  # already an Array
	print(features)

	
	# Scaled based on desired resolution
	var scaling_factor: Vector2 = Vector2((MAP_RESOLUTION.x - BORDER_RESOLUTION) * PIXELS_PER_TILE / gen_screen_resolution.x, (MAP_RESOLUTION.y - BORDER_RESOLUTION) * PIXELS_PER_TILE / gen_screen_resolution.y)
	for f in sizes.size():
		for s in sizes[f].size():
			sizes[f][s] = int(sizes[f][s] * scaling_factor.length())
			

	for a in spawn_area.size():
		for area in spawn_area[a]:
			
			area[0][0] = int(area[0][0] * scaling_factor.x) + BORDER_RESOLUTION * PIXELS_PER_TILE
			area[0][1] = int(area[0][1] * scaling_factor.y) + BORDER_RESOLUTION * PIXELS_PER_TILE
			
			area[1][0] = int(area[1][0] * scaling_factor.x) + BORDER_RESOLUTION * PIXELS_PER_TILE
			area[1][1] = int(area[1][1] * scaling_factor.y) + BORDER_RESOLUTION * PIXELS_PER_TILE
			
			
	
	
	#Calculate number of features
	var number_of_features = 0
	for f in features.size():
		number_of_features += occurences[f]
	#print(number_of_features)
	var arrayToReturn = [sqrt((((MAP_RESOLUTION.x - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE) * ((MAP_RESOLUTION.y - BORDER_RESOLUTION * 2) * PIXELS_PER_TILE)) / (number_of_features * PI * sphere_packing_constant)), features, spawn_area, occurences, layers, gen_depth, sub_occurences, sizes]
	# Return min_distance, features, spawn_area, occurences, gen_depth, sub_occurences, sizes
	#print(arrayToReturn)
	return arrayToReturn
	#return [sqrt((SCREEN_RESOLUTION.x * SCREEN_RESOLUTION.y) / (number_of_features * PI * sphere_packing_constant)), features, spawn_area, occurences, gen_depth, sub_occurences, sizes]
	
#Returns [PackedVector3Array, Array[Array], Vector2i]
func _generate_points(min_distance, features, spawn_area, occurences, gen_depth, sub_occurences, sizes) -> Array:
	return []
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
				if depth >= gen_depth[f]:
					continue
				var num_children = sub_occurences[f][depth]
				
				var radius = sizes[f][depth]
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
				
				
	print(points.size())
	return [points, chunks]
	"""

# Generates the mesh
func _generate_mesh(baseTerrain: Array): # 
	# Mesh variables
	var mesh = ArrayMesh.new()
	var arrays = []
	var quad_size: int = PIXELS_PER_TILE
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	print(baseTerrain)
	# Generates mesh
	for row: int in MAP_RESOLUTION.y:
		for col: int in MAP_RESOLUTION.x:
			var x: int = col * quad_size
			var y: int = row * quad_size
			
			var i = vertices.size()  # index of first vertex in this quad
			
			# Define the 4 vertices of the quad (clockwise or CCW)
			vertices.push_back(Vector2(x, y))
			vertices.push_back(Vector2(x + quad_size, y))
			vertices.push_back(Vector2(x + quad_size, y + quad_size))
			vertices.push_back(Vector2(x, y + quad_size))
		
			#Hard sets quads to ocean
			if col < (BORDER_RESOLUTION - 1) or row < BORDER_RESOLUTION - 1 or col > (MAP_RESOLUTION.x - (BORDER_RESOLUTION) + 1) or row > (MAP_RESOLUTION.y - BORDER_RESOLUTION + 1):
				
				var color = biome_colours[8] #WATER
				colors.append_array([color, color, color, color])
				# Define two triangles (quad = 2 triangles)
				indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
				continue
				
			#Hard sets quads to beach
			if col <= (BORDER_RESOLUTION) or row <= BORDER_RESOLUTION or col >= (MAP_RESOLUTION.x - (BORDER_RESOLUTION)) or row >= (MAP_RESOLUTION.y - BORDER_RESOLUTION):
				
				var color = biome_colours[4] #DESERT/Sand -> Needs change3z
				colors.append_array([color, color, color, color])
				# Define two triangles (quad = 2 triangles)
				indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
				continue
			var found = false
			for type in baseTerrain:
				
				var IN = false
				for area in type[0]:
					if col * PIXELS_PER_TILE >= area[0][0] and col * PIXELS_PER_TILE <= area[1][0]:
						if row * PIXELS_PER_TILE >= area[0][1] and row * PIXELS_PER_TILE <= area[1][1]:
							IN = true
				if IN:
					colors.append_array([type[1],type[1],type[1],type[1]])
					indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
					found = true
					break
	
			if found == false:
				var color = biome_colours[0]
				colors.append_array([color, color, color, color])
				indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
			"""
			# Calculate the closest feature to this point
			var closest_feature = Vector2(-1, -1) # distance squared, feature id
			var current_chunk = Vector2i(
				floor((col * PIXELS_PER_TILE) / GLOBAL_chunk_length),
				floor((row * PIXELS_PER_TILE)/ GLOBAL_chunk_length))
			var d_d = 2 # The range of chunks to check (-d_d < chunk < d_dd)
			
			while closest_feature.x == -1 and d_d < GLOBAL_CHUNK_COUNT.x:
				

				for dy in range(-d_d,d_d+1):
					for dx in range(-d_d, d_d+1):
						var target_chunk = current_chunk + Vector2i(dx,dy)
						if ((0 <= target_chunk.x and target_chunk.x < GLOBAL_CHUNK_COUNT.x) and (0 <= target_chunk.y and target_chunk.y < GLOBAL_CHUNK_COUNT.y)):
							for p in chunks[target_chunk.x][target_chunk.y]:
								var distance = pow((x - p.x),2) + pow((y - p.y),2) # Calculate distance squared
								if (p.z == 0 and distance < origin_radius): # If it's within origin radius from origin, force it to be origin
									closest_feature = Vector2(distance, p.z)
									break
								if ((closest_feature.x == -1) or (distance < closest_feature.x)): # New closest feature
									closest_feature = Vector2(distance,p.z)
				if (closest_feature.x == -1):
					d_d += 1
					#print("D_D must be upped for Col:", col, " and row: ", row)
				
			# Generate the color for the whole quad
			var color = biome_colours[closest_feature.y]
			#var color = biome_colours[y]
			#if (sqrt(closest_feature.x) > (col * PIXELS_PER_TILE) or sqrt(closest_feature.x) > (2 * MAP_RESOLUTION.x - col * PIXELS_PER_TILE)
			#or sqrt(closest_feature.x) > (row * PIXELS_PER_TILE) or sqrt(closest_feature.x) > MAP_RESOLUTION.y - (row * PIXELS_PER_TILE)):
			#	color = Color.DARK_BLUE
			
			colors.append_array([color, color, color, color])
			# Define two triangles (quad = 2 triangles)
			indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
			"""
	
	print(colors.size())
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$"Ground Mesh".mesh = mesh
