extends Camera2D

@export var pan_speed = 22 * 60
@export var zoom_speed = 2
@export var zoom_min = 3
@export var zoom_max = 0.5


func _process(delta: float) -> void:
	# Panning
	var camera_to = Vector2(0,0)
	if Input.is_action_pressed("move_camera_left"):
		camera_to += Vector2(-1,0)
	if Input.is_action_pressed("move_camera_up"):
		camera_to += Vector2(0,-1)
	if Input.is_action_pressed("move_camera_right"):
		camera_to += Vector2(1,0)
	if Input.is_action_pressed("move_camera_down"):
		camera_to += Vector2(0,1)
	self.global_position += camera_to.normalized() * pan_speed / self.zoom.length() * delta

	# Zooming
	if Input.is_action_just_released("zoom_in"):
		self.zoom += Vector2(1,1) * zoom_speed * zoom_speed * delta
	if Input.is_action_just_released("zoom_out"):
		self.zoom -= Vector2(1,1) * zoom_speed * delta
	self.zoom.x = clamp(self.zoom.x, zoom_max, zoom_min)
	self.zoom.y = clamp(self.zoom.y, zoom_max, zoom_min)
