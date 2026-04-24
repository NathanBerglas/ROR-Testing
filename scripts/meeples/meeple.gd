extends Node2D
class_name meeple

var playerID = null

@export var speed: float = 200
@export var acceleration: float = 300

const HEX_DIRS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

@export var label: Label
@export var rb: CharacterBody2D
@export var sprite: Sprite2D

var redirected_from: Array = []
var selected = false #Determines if a meeple is selected
var path: Array = [] #destination of a meeple
var queued_path: Array = [] #destination of a meeple
var shouldBeMoving = false
var waiting = false
var inqueue = false; # british behaviour, french sounding word
var pause_a_tick = false; # When arriving to prevent merge skipping
var attackTarget = null
var UNIQUEID = null #Unique Id for every meeple on a team by unit type
#When I say Unique, I mean UNIQUE
var groupNum = 0
var min_distance = 9 # Squared
var HP = 1
var type = "Meeple"
var superType = "Building"

func _ready():
	label.text = str(HP)
	

#func _process(delta): #runs on each meeple every tick
	#label.text = str(HP)
	
	#if (path != null and shouldBeMoving): #if a meeple has somewhere to go, goes to it
	#	_go_to_target(delta)
	
	#if dest != null and closeEnough(): #meeple reaches destination
		#dest = null


func update_hp(hp: int):
	HP += hp
	if HP <= 0:
		get_parent().freeMeeple(UNIQUEID)
	label.text = str(HP)


#func hasMouse(): #Checks if the mouse is within the meeple
	#var radius = 220 #should be set to meeple radius squared
	#var mousePos = get_global_mouse_position()
	#
	#var dif = rb.global_position - mousePos
	#
	#if dif.length_squared() < radius:
		#return true
	#return false


func is_selected():
	selected = true
	sprite.modulate = Color(2.5, 3, 3)


func is_unselected():
	selected = false
	sprite.modulate = Color(1, 1, 1)


#func _go_to_target(delta):
	#if path.size() <= 0:
		#path = null
		#return
	#
	#var to_target = path[0] - rb.global_position
	#var dist = to_target.length_squared()
	#var speed_towards_target = rb.linear_velocity.dot(to_target.normalized())
	#
	#if dist > min_distance and speed_towards_target < speed: # Checks if meeple is close to target point
		#var force = to_target.normalized() * min(acceleration, abs(speed_towards_target-speed) / delta) # If acceleration would overshoot
		#rb.apply_central_force(force)
		#
	#
	#if closeEnough():
		#rb.linear_velocity = Vector2.ZERO
		#rb.angular_velocity = 0.0
		#rb.set_global_position(path[0])
	#
		#path.pop_at(0)
		#if path.size() == 0:
			#path = null


#func closeEnough(): #checking if a meeple is close enough to their destination
	#var dist = rb.global_position - path[0]
#
	#if ((dist.x * dist.x) < 3 and (dist.y * dist.y) < 3):
		#return true
	#return false


func _on_rigid_body_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Input.is_action_just_pressed("select"):
		if selected:
			is_unselected()
		else:
			is_selected()
