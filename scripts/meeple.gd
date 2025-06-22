extends Node2D

@onready var rb = $RigidBody2D

@export var area_2d: Area2D
@export var speed: float = 200
@export var acceleration: float = 300
var min_distance = 9 # Squared

var target = Vector2(0,0)

func _physics_process(delta):
	_go_to_target(delta)

# Marches Meeple to Target
func _go_to_target(delta):
	var to_target = target - rb.global_position
	var dist = to_target.length_squared()
	var speed_towards_target = rb.linear_velocity.dot(to_target.normalized())
	
	if dist > min_distance and speed_towards_target < speed: # Checks if meeple is close to target point
		var force = to_target.normalized() * min(acceleration, abs(speed_towards_target-speed) / delta) # If acceleration would overshoot
		rb.apply_central_force(force)
