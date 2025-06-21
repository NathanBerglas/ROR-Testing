extends MeshInstance2D

@export var QUAD_WIDTH = 10
@export var QUAD_HEIGHT = 10
@export var ROWS = 108
@export var COLS = 192

@export var x_0 = COLS/2 # Define the colour origin
@export var y_0 = ROWS/2 # Defaults to the centre
@export var COLOUR_MUTATION = 8

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

func _generate_mesh():
	var mesh = ArrayMesh.new()
	var arrays = []
	
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
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
			
			# Generate a random color for the whole quad
			var color = Color.BLACK
			colors.append_array([color, color, color, color])
			'''
			var r = randi_range(0,255)
			var g = randi_range(0,255)
			var b = randi_range(0,255)
			var color
			var old_color_left
			var old_color_up
			if (row == 0 && col == 0):
				color = Color.from_rgba8(r,g,b)
				old_color_left = color
				old_color_up = color
			elif (row == 0):
				old_color_left = colors[(col - 1)*4] # Left colour assigned
				old_color_up = old_color_left
			elif (col == 0):
				old_color_up = colors[((row-1)*COLS)*4] # Up colour assigned
				old_color_left = old_color_up
			else:
				old_color_left = colors[(row*COLS + col - 1)*4] # Last colour assigned
				old_color_up = colors[((row-1)*COLS + col)*4] # Last colour assigned
			var old_color = Color.from_rgba8((old_color_left.r8+old_color_up.r8) / 2, (old_color_left.g8+old_color_up.g8) / 2, (old_color_left.b8+old_color_up.b8) / 2) # Average of adjacent colours
			var r_offset = randi_range(-COLOUR_MUTATION,COLOUR_MUTATION)
			var g_offset = randi_range(-COLOUR_MUTATION,COLOUR_MUTATION)
			var b_offset = randi_range(-COLOUR_MUTATION,COLOUR_MUTATION)
			color = Color.from_rgba8(clamp(old_color.r8 + r_offset, 0, 255), clamp(old_color.g8 + r_offset, 0, 255), clamp(old_color.b8 + r_offset, 0, 255))
			colors.append_array([color, color, color, color])
			'''
			
			# Define two triangles (quad = 2 triangles)
			indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
	
	var visited = 0
	var layer = 0
	var x = x_0
	var y = y_0
	var origin_color = Color.AQUAMARINE
	colors[(y_0*COLS + x_0)*4] = origin_color # Set the colour of this cell
	colors[(y_0*COLS + x_0)*4+1] = origin_color
	colors[(y_0*COLS + x_0)*4+2] = origin_color
	colors[(y_0*COLS + x_0)*4+3] = origin_color
				
	var offset = [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]
	while (layer < min(floor(ROWS/2.), floor(ROWS/2.))):
		for i in range(4): # In four directions: right, down, left, up
			for j in range(layer*2): # Step layer * 2 times
				var distance_to_origin = sqrt(pow(x-x_0,2)+pow(y-y_0,2))
				var color# = Color.from_rgba8(0,distance_to_origin * 255 / sqrt(pow(x_0,2)+pow(y_0,2)),0) # Scaled off distance
				var rand = randf_range(0,1)
				if (rand > _sigmoid(distance_to_origin-9)):
					color = Color.REBECCA_PURPLE
				else:
					color = Color.BLACK	
				#var color = Color.from_rgba8 _sigmoid()
				colors[(y*COLS + x)*4] = color # Set the colour of this cell
				colors[(y*COLS + x)*4+1] = color
				colors[(y*COLS + x)*4+2] = color
				colors[(y*COLS + x)*4+3] = color
				x += offset[i].x
				y += offset[i].y
				visited += 1
			# Is at a corner
		# Is now in the top left corner
		x -= 1 # Goes up and to the left to the next layer
		y -= 1
		layer += 1 # Increases layer count for while loop, and to track required steps
		
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = mesh

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
	
	for f in len(features):
		for occ in occurences[f]:
			if(f == 0): # Make origin at the center
				points.append(Vector3(x_0,y_0,0))
			else:
				points.append(Vector3(randi_range(M_TopLeft.x, M_BottomRight.x),randi_range(M_TopLeft.y, M_BottomRight.y),f)) #TODO: Make this not normalized
			var main_point = points[-1]
			var main_point_v2 = Vector2(main_point.x, main_point.y)
			for sub_occ in sub_occurences[f].size():
				var new_point = main_point_v2 + (main_point_v2.normalized() * sizes[f][sub_occ]).rotated(randf_range(0,2*PI)) # A point is size[occ][sub_occ] away from main_point
				points.append(Vector3(round(new_point.x), round(new_point.y), f))
	
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
			
			# Generate a random color for the whole quad
			var color = Color.WHITE
			if (points.has(Vector3(col,row,0))): # Origin
				color = Color.BLACK
			elif (points.has(Vector3(col,row,1))): # Forest
				color = Color.FOREST_GREEN
			elif (points.has(Vector3(col,row,2))): # Plains
				color = Color.LIGHT_GREEN
			elif (points.has(Vector3(col,row,3))): # Lake
				color = Color.ROYAL_BLUE
			elif (points.has(Vector3(col,row,4))): # Desert
				color = Color.SANDY_BROWN
			elif (points.has(Vector3(col,row,5))): # Tundra
				color = Color.SKY_BLUE
			elif (points.has(Vector3(col,row,5))): # Rainforest
				color = Color.GREEN_YELLOW
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
