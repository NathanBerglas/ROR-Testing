extends Node2D
class_name meeple



@export var area_2d: Area2D
@export var speed: float = 20#0
@export var acceleration: float = 300


const HEX_DIRS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

var label = null
var rb = null
var sprite = null
var selected = false #Determines if a meeple is selected
var path = null #destination of a meeple
var shouldBeMoving = true
var UNIQUEID = null #Unique Id for every meeple on a team
#When I say Unique, I mean UNIQUE
var size = 1 #Size of the ARMY hashtag troops slay
var groupNum = 0
var min_distance = 9 # Squared
var pos = Vector2i(0, 0)
var HP = 1

var type = "Meeple"

func _process(delta): #runs on each meeple every tick
	label.text = str(HP)
	
	#if (path != null and shouldBeMoving): #if a meeple has somewhere to go, goes to it
	#	_go_to_target(delta)
	
	#if dest != null and closeEnough(): #meeple reaches destination
		#dest = null
	
func _physics_process(delta: float) -> void:
	if !shouldBeMoving:
		return
	var next_hex: Vector2 = path[0]
	var dir_to_next_hex = (next_hex - global_position) / (next_hex - global_position).length()
	if (next_hex - global_position).length() >= speed: # Not yet arrived
		global_position += dir_to_next_hex * speed
		return
	
	var next_hex_tile = grid.probe(path[0])
	if (next_hex_tile.classification == 3):
		grid.meeple_end_merge()
		queue_free()
	else:
		path.pop(0)
		shouldBeMoving = false
		
func closeEnough(): #checking if a meeple is close enough to their destination
	var dist = rb.global_position - path[0]

	if ((dist.x * dist.x) < 3 and (dist.y * dist.y) < 3):
		return true
	return false
	
func hasMouse(): #Checks if the mouse is within the meeple
	var radius = 220 #should be set to meeple radius squared
	var mousePos = get_global_mouse_position()
	
	var dif = rb.global_position - mousePos
	
	if dif.length_squared() < radius:
		return true
	return false
	

func highlight(colour):
	sprite.modulate = colour  # White Highlight
	
func remove_highlight(colour):
	sprite.modulate = colour  # Red highlight
# Marches Meeple to Target

func _go_to_target(delta):
	if path.size() <= 0:
		path = null
		return
	
	var to_target = path[0] - rb.global_position
	var dist = to_target.length_squared()
	var speed_towards_target = rb.linear_velocity.dot(to_target.normalized())
	
	if dist > min_distance and speed_towards_target < speed: # Checks if meeple is close to target point
		var force = to_target.normalized() * min(acceleration, abs(speed_towards_target-speed) / delta) # If acceleration would overshoot
		rb.apply_central_force(force)
		
	
	if closeEnough():
		rb.linear_velocity = Vector2.ZERO
		rb.angular_velocity = 0.0
		rb.set_global_position(path[0])
	
		path.pop_at(0)
		if path.size() == 0:
			path = null
