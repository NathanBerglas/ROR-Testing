extends MeshInstance2D

@export var QUAD_WIDTH = 50
@export var QUAD_HEIGHT = 50
@export var ROWS = 10
@export var COLS = 10

func _ready():
	if Engine.is_editor_hint():
		return
	_generate_mesh()

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
			var color = Color.from_rgba8(col*255/COLS,row*255/ROWS,255)
			colors.append_array([color, color, color, color])
			
			# Define two triangles (quad = 2 triangles)
			indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])
	
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = mesh
