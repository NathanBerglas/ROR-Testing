extends Node2D

@export var targetMarker: Sprite2D
@export var meeple_prefab: PackedScene

var group: Array[Array] = [[]]
var group_targets: Array[Vector2] = [Vector2(1000,500)]

func _process(delta):
	if Input.is_action_just_pressed("spawn_meeple"):
		var instance = meeple_prefab.instantiate()
		
		# Set instance's data
		instance.global_position = get_global_mouse_position()
		instance.target = group_targets[0]
		
		# Create instance
		add_child(instance)
		group[0].push_back(instance)
		print("Spawned meeple")
	elif Input.is_action_just_pressed("order"):
		group_targets[0] = get_global_mouse_position()
		targetMarker.global_position = group_targets[0]
		for m in group[0]:
			m.target = group_targets[0]
