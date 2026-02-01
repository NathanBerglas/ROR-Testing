extends Node2D

@onready var rb = $RigidBody2D
@onready var label = $RigidBody2D/Label

@export var sprite: Sprite2D


@export var area_2d: Area2D
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

var attackTimer = 0
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
var attackTarget = null
var attackRange = 1
var type = "Meeple"

func _process(delta): #runs on each meeple every tick
	label.text = str(HP)
	
	
	if attackTarget:
		if inAttackRange(attackTarget.pos):
			attack(attackTarget, delta)
	
	if (path != null and shouldBeMoving): #if a meeple has somewhere to go, goes to it
		_go_to_target(delta)
	
	#if dest != null and closeEnough(): #meeple reaches destination
		#dest = null
	
	
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


func attack(target, delta):
	attackTimer += delta
	if attackTimer >= 1:
		attackTimer = 0
		if target.type == "Meeple":
			if path == null:
				target.HP -= HP * 2
			else:
				target.HP -= int(HP)
			
			if target.HP <= 0:
				attackTarget = null
			
			
		else:
			if path == null:
				target.hp -= size * 10
			else:
				target.hp -= int(size * 5)
			
			if target.hp <= 0:
				attackTarget = null
				
		
		
		
func inAttackRange(target):
	if target == null:
		return false
	var distToTarget = pos - target
	
	for v in HEX_DIRS: #Need to change based on varying range
		if distToTarget == v:
			return true
			
	return false
	
