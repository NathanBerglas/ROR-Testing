extends Node2D


@export var SCREEN_RESOLUTION: Vector2i = Vector2i(1920,1080)
@export var BORDER: int = 400
@export var TILES_ALONG_X: int = 192
@export var gen_data: JSON

var map_size: Vector2i = Vector2i(SCREEN_RESOLUTION.x + BORDER,SCREEN_RESOLUTION.y + BORDER)
var tiles_along_x_map: int = TILES_ALONG_X+floor(BORDER / (SCREEN_RESOLUTION.x / TILES_ALONG_X))
var map_cols: int = (map_size.x / SCREEN_RESOLUTION.x) * tiles_along_x_map
var map_rows: int = floor(map_cols * map_size.y / map_size.x)

const max_poisson_attempts_1d = 100
const max_poisson_attempts_2d = 100
const sphere_packing_constant = 0.8

# 1 dimensional poisson disk distribution
func _poisson_dd_1d(min, max, n: int, density):
	var start_time = Time.get_ticks_usec()
	var range = max-min
	var min_distance = ceil(range/(n-2)) / density # The farthest each can get and still fit divided by density. If density >= 1, all can fit
	var chunk_count = floor(range / min_distance)
	var ending_remainder = (range / min_distance) - chunk_count
	
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

# 1 dimensional poisson disk distribution
func _poisson_dd_2d(top_left: Vector2i, bottom_right: Vector2i, n: int, total:int, density: float, prev_points: Array[Vector2i]):
	#var start_time = Time.get_ticks_usec()
	var range_x = bottom_right.x-top_left.x
	var range_y = bottom_right.y-top_left.y
	var min_distance = sqrt((range_x * range_y) / (total * PI * sphere_packing_constant))  # The farthest each can get and still fit divided by density. If density >= 1, all can fit
	var chunk_count_x
	var chunk_count_y
	var ending_remainder_x
	var ending_remainder_y
	if min_distance >= 1:
		chunk_count_x = floor(range_x / min_distance)
		chunk_count_y = floor(range_y / min_distance)
		ending_remainder_x = (range_x / min_distance) - chunk_count_x
		ending_remainder_y = (range_y / min_distance) - chunk_count_y
	else:
		chunk_count_x = 1
		chunk_count_y = 1
		ending_remainder_x = 0
		ending_remainder_y = 0
	
	var points: Array[Vector2i] = prev_points
	
	var chunks: Array # Each point is placed in a chunk. Each chunk is exactly min_distance_x wide starting from min (stretches to max)
	for cx in chunk_count_x: # Initialize the array
		chunks.push_back([])
		for cy in chunk_count_y:
			chunks[cx].push_back([])
	
	# Put prev_points into points
	for point in prev_points:
		chunks[min(floor(point.x / min_distance),chunk_count_x-1)][min(floor(point.y / min_distance),chunk_count_y-1)].push_back(point)

	for i in n: # For each point
		for attempt in max_poisson_attempts_2d: # Cap number of attempts in case to prevent infinite loop
			var sucess = true
			var x = Vector2i(randi_range(top_left.x, bottom_right.x),randi_range(top_left.y, bottom_right.y))
			var chunk_id_x = min(floor(x.x / min_distance),chunk_count_x-1) # To not overrun
			var chunk_id_y = min(floor(x.y / min_distance),chunk_count_y-1)
			for dx in range(-1,2):
				for dy in range(-1,2):
					var nx = chunk_id_x + dx
					var ny = chunk_id_y + dy
					if nx >= 0 and ny >= 0 and nx < chunk_count_x and ny < chunk_count_y:
						for point in chunks[nx][ny]:
							if point.distance_squared_to(x) < min_distance * min_distance:
								sucess = false
								break
			if (sucess):
				chunks[chunk_id_x][chunk_id_y].push_back(x)
				points.push_back(x)
				break
			if (attempt == max_poisson_attempts_1d-1):
				print("Biome Gen Timed out 2d!")
	#print(Time.get_ticks_usec() - start_time, " microseconds passed") # Debugging
	return points.slice(-n, points.size())

func _ocean(distance: int) -> Vector2:
	var shore_length: int = map_cols * 2 + map_rows
	distance *= shore_length / 100
	if (distance > map_cols):
		distance -= map_cols
		if (distance > map_rows):
			distance -= map_rows
			return Vector2(distance,map_rows)
		return Vector2(0,distance)
	return Vector2(distance,0)
	
func _ready():
	_generate_mesh()

# Generates the mesh
func _generate_mesh():
	var mesh = ArrayMesh.new()
	var arrays = []
	
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
		
	# Map size
	var cols: int = TILES_ALONG_X
	var rows: int = floor(cols * SCREEN_RESOLUTION.y / SCREEN_RESOLUTION.x)
	var M_TopLeft = Vector2(0,0)
	var M_BottomRight = Vector2(cols, rows)
	var points = PackedVector3Array() # (x, y, feature index)
	var major_points = PackedVector3Array() # (x,y, feature index), only for major occurences
	
	#Resource data
	var json_received = gen_data.data
	var features = PackedStringArray()
	var spawn_area: Array[Array] = [] # [0] is the top left, [1] is bottom right Vector2i
	var occurences = PackedInt32Array()
	var gen_depth = PackedInt32Array()
	var sub_occurences: Array[Array] = [] # sub_occurences[i] is an array of integers of length gen_depth[i], where i is the ith feature
	var sizes: Array[Array] = [] # sizes[i] is an array of integers of length gen_depth[i], where i is the ith feature
	
	# Initialize data from JSON
	for feature in json_received["features"]:
		features.append(feature["name"])
		spawn_area.append(feature["spawn_area"])
		occurences.append(feature["occurences"])
		gen_depth.append(feature["gen_depth"])
		sub_occurences.append(feature["sub_occurences"])  # already an Array
		sizes.append(feature["sizes"])  # already an Array
	var gen_screen_resolution = Vector2(json_received["x-resolution"], json_received["y-resolution"])
	var gen_tiles = Vector2(json_received["x-tiles"], json_received["y-tiles"])
	var quad_width: int = map_size.x / cols
	var quad_height: int = map_size.y / rows
	
	# Scaled based on desired resolution
	for f in sizes.size():
		for s in sizes[f].size():
			sizes[f][s] *= sqrt((cols*cols + rows*rows) / gen_tiles.dot(gen_tiles))
			sizes[f][s] = floor(sizes[f][s])
	for area in spawn_area:
		for p in 2:
				area[p][0] *= (cols / gen_screen_resolution.x)
				area[p][1] *= (rows / gen_screen_resolution.y)
				area[p][0] = floor(area[p][0])
				area[p][1] = floor(area[p][1])
	#Calculate number of features
	var number_of_features = 0
	for f in features.size():
		number_of_features += occurences[f]
	
	# Generate Vectors of previous points
	var prev_points: Array[Vector2i]
	for p in points:
		prev_points.push_back(Vector2i(p.x, p.y))
	
	for f in features.size():
		for occ in occurences[f]:
			var top_left = Vector2i(floor(spawn_area[f][0][0]), floor(spawn_area[f][0][1]))
			var bottom_right = Vector2i(floor(spawn_area[f][1][0]), floor(spawn_area[f][1][1]))
			var occurence = _poisson_dd_2d(top_left, bottom_right, 1, number_of_features, 1, prev_points)[0]
			occurence += Vector2i(tiles_along_x_map-TILES_ALONG_X, tiles_along_x_map-TILES_ALONG_X)/2 # Shift by the border
			points.append(Vector3(occurence.x, occurence.y, f))
			# Stack of [position, depth]
			var stack: Array = [[occurence, 0]]
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
	var ocean_distances: Array = range(0,BORDER/3,1)
	for p in ocean_distances.size():
		var ocean_point: Vector2 = _ocean(ocean_distances[p])
		points.push_back(Vector3(ocean_point.x, ocean_point.y, -1))
		
	# Generates mesh
	for row: int in map_rows:
		for col: int in map_cols:
			var x: int = col * quad_width
			var y: int = row * quad_height
			
			var i = vertices.size()  # index of first vertex in this quad
			
			# Define the 4 vertices of the quad (clockwise or CCW)
			vertices.push_back(Vector2(x, y))
			vertices.push_back(Vector2(x + quad_width, y))
			vertices.push_back(Vector2(x + quad_width, y + quad_height))
			vertices.push_back(Vector2(x, y + quad_height))
			
			# Calculate the closest feature to this point
			var closest_feature = Vector2(-1, -1) # distance squared, feature id
			for p in points:
				var distance = (col-p.x) * (col-p.x) + (row-p.y) * (row-p.y) # Calculate distance squared
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
			if (row == floor(map_rows/2) and col == floor(map_cols/2)):
				color = Color.WEB_PURPLE
			#if  !(((map_rows-rows) < row and row < rows) and ((map_cols-cols) < col and col < cols)): # Inside point area
			#	color = Color.WEB_MAROON
			#if (closest_feature.x == 0): # Is on a point
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
