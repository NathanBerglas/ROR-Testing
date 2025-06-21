extends MeshInstance2D

@export var QUAD_WIDTH = 10
@export var QUAD_HEIGHT = 10
@export var ROWS = 108
@export var COLS = 192

@export var x_0 = COLS/2 # Define the colour origin
@export var y_0 = ROWS/2 # Defaults to the centre
@export var starting_area = 10

@export var gen_data = JSON

func _sigmoid(x):
	var SIG_SCALE = 1./10. # Scales how fast sigmoid noramlizes
	return (exp(SIG_SCALE*x) / (1. + exp(SIG_SCALE*x)))

func _ready():
	if Engine.is_editor_hint():
		return
	#_generate_mesh()
	_generate_mesh_PC()
#Hi Nate
@export var regenerate: bool:
	set(value):
		if value:
			#_generate_mesh()
			_generate_mesh_PC()
			regenerate = false  # reset the toggle

# Point and Circle Generation
func _generate_mesh_PC():
	var mesh = ArrayMesh.new()
	var arrays = []
	
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
		
	# Map size
	var M_TopLeft = Vector2(0,0)
	var M_BottomRight = Vector2(COLS, ROWS)
	var points = PackedVector3Array() # (x, y, feature index)
	
	#Resource data
	var json_received = gen_data.data
	var features = PackedStringArray()
	var occurences = PackedInt32Array()
	var gen_depth = PackedInt32Array()
	var sub_occurences: Array[Array] = [] # sub_occurences[i] is an array of integers of length gen_depth[i], where i is the ith feature
	var sizes: Array[Array] = [] # sizes[i] is an array of integers of length gen_depth[i], where i is the ith feature
	
	# Initialize data from JSON
	for feature in json_received["features"]:
		features.append(feature["name"])
		occurences.append(feature["occurences"])
		gen_depth.append(feature["gen_depth"])
		sub_occurences.append(feature["sub_occurences"])  # already an Array
		sizes.append(feature["sizes"])  # already an Array

	for f in features.size():
		for occ in occurences[f]:
			# Base point (either origin or random)
			var root_point
			if (f==0):
				root_point = Vector2(x_0, y_0) 
			else:
				root_point = Vector2(randi_range(M_TopLeft.x, M_BottomRight.x), randi_range(M_TopLeft.y, M_BottomRight.y))
			
			points.append(Vector3(root_point.x, root_point.y, f))

			# Stack of [position, depth]
			var stack: Array = [[root_point, 0]]

			while stack.size() > 0:
				var item = stack.pop_back()
				var center = item[0]
				var depth = item[1]

				# Stop if we've reached max depth
				if depth >= gen_depth[f]:
					continue

				var num_children = sub_occurences[f][depth]
				var radius = sizes[f][depth]

				for i in num_children:
					# Random angle around the circle
					var angle = randf_range(0, TAU)
					var offset = Vector2(radius, 0).rotated(angle)
					var new_point = center + offset
					points.append(Vector3(round(new_point.x), round(new_point.y), f))

					# Queue it up for the next depth layer
					depth += 1
					stack.append([new_point, depth])
	
	# Generates mesh
	for row in ROWS:
		for col in COLS:
			var x = col * QUAD_WIDTH
			var y = row * QUAD_HEIGHT
			
			var i = vertices.size()  # index of first vertex in this quad
			
			# Define the 4 vertices of the quad (clockwise or CCW)
			vertices.push_back(Vector2(x, y))
			vertices.push_back(Vector2(x + QUAD_WIDTH, y))
			vertices.push_back(Vector2(x + QUAD_WIDTH, y + QUAD_HEIGHT))
			vertices.push_back(Vector2(x, y + QUAD_HEIGHT))
			
			# Calculate the closest feature to this point
			var closest_feature = Vector2(-1, -1) # distance squared, feature id
			for p in points:
				var distance = pow(col-p.x,2) + pow(row-p.y,2) # Calculate distance squared
				if ((closest_feature.x == -1) or (distance < closest_feature.x)): # New closest feature
					closest_feature = Vector2(distance,p.z) 
			
			# Generate the color for the whole quad
			var color = Color.WHITE
			if (pow(col-x_0,2) + pow(row-y_0,2) < pow(starting_area,2)): # Force starting area
				color = Color.BLACK
			elif (closest_feature.y == 0): # Origin
				color = Color.BLACK
			elif (closest_feature.y == 1): # Forest
				color = Color.FOREST_GREEN
			elif (closest_feature.y == 2): # Plains
				color = Color.LIGHT_GREEN
			elif (closest_feature.y == 3): # Lake
				color = Color.ROYAL_BLUE
			elif (closest_feature.y == 4): # Desert
				color = Color.SANDY_BROWN
			elif (closest_feature.y == 5): # Tundra
				color = Color.SKY_BLUE
			elif (closest_feature.y == 6): # Rainforest
				color = Color.GREEN_YELLOW
			if (closest_feature.x == 0): # Is on a point
				color = Color.WEB_PURPLE
			colors.append_array([color, color, color, color])
			# Define two triangles (quad = 2 triangles)
			indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
			
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = mesh

# Algorithm idea (Point & Circle division)
# Start with a closed set M to be the set of all points on the map
# For each feature, choose n random points, where n is a random number within a range decided per feature
# Create circles centered on each point. Expand each circle until it intersects with a circle centered on a point from another feature
# At the intersection of the circle, start a new curve that will trace the intersection of the circles as they continue to expand until all points in M are assigned
# Every point within the curve of a feature is assigned to that biome
