extends Node2D

@onready var rb = $RigidBody2D
@export var sprite: Sprite2D

@export var area_2d: Area2D
@export var speed: float = 200
@export var acceleration: float = 300

var selected = false #Determines if a meeple is selected
var dest = null #destination of a meeple


var min_distance = 9 # Squared


#var target = Vector2(0,0)

func _physics_process(delta): #runs on each meeple every tick
	
	if selected:
		highlight()
	else:
		remove_highlight()
		
	if (dest != null): #if a meeple has somewhere to go, goes to it
		_go_to_target(delta)
		
	#if dest != null and closeEnough(): #meeple reaches destination
		#dest = null
	
	
func closeEnough(): #checking if a meeple is close enough to their destination
	var dist = rb.global_position - dest
	if ((dist.x * dist.x) < 3 and (dist.y * dist.y) < 3):
		return true
	return false
	
func hasMouse(): #Checks if the mouse is within the meeple
	var radius = 800 #should be set to meeple radius squared
	var mousePos = get_global_mouse_position()
	
	var dif = rb.global_position - mousePos
	
	if dif.length_squared() < radius:
		return true
	return false
	

func highlight():
	sprite.modulate = Color(1, 1, 1)  # Reset to white
	

func remove_highlight():
	sprite.modulate = Color(1, 0, 0)  # Red highlight
# Marches Meeple to Target

func _go_to_target(delta):
	var to_target = dest - rb.global_position
	var dist = to_target.length_squared()
	var speed_towards_target = rb.linear_velocity.dot(to_target.normalized())
	
	if dist > min_distance and speed_towards_target < speed: # Checks if meeple is close to target point
		var force = to_target.normalized() * min(acceleration, abs(speed_towards_target-speed) / delta) # If acceleration would overshoot
		rb.apply_central_force(force)
		
