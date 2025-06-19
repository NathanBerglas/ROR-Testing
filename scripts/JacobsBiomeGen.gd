extends MeshInstance2D

@export var QUAD_WIDTH = 10
@export var QUAD_HEIGHT = 10
@export var ROWS = 108
@export var COLS = 192

@export var x_0 = COLS/2 # Define the colour origin
@export var y_0 = ROWS/2 # Defaults to the centre
@export var COLOUR_MUTATION = 8

func _ready():
	if Engine.is_editor_hint():
		return
	_generate_mesh()
#Hi Jacob
@export var regenerate: bool:
	set(value):
		if value:
			_generate_mesh()
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
				var color = Color.from_rgba8(0,distance_to_origin * 255 / sqrt(pow(x_0,2)+pow(y_0,2)),0) # Scaled off distance
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
