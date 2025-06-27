extends Node2D

@export var targetMarker: Sprite2D
@export var meeple_prefab: PackedScene

var group: Array[Array] = [[]]
var group_targets: Array[Vector2] = [Vector2(1000,500)]
var teammates = []

func _process(_delta):
	if Input.is_action_just_pressed("spawn_meeple"):
		var instance = meeple_prefab.instantiate()
		
		# Set instance's data
		
		instance.global_position = get_global_mouse_position()
		#instance.target = group_targets[0]
		
		# Create instance
		add_child(instance)
		group[0].push_back(instance)
		print("Spawned meeple")
		
		
	elif Input.is_action_just_pressed("super_order"):
		group_targets[0] = get_global_mouse_position()
		targetMarker.global_position = group_targets[0]
		
		for m in group[0]:
			m.dest = group_targets[0]
			
			
	elif Input.is_action_just_pressed("order"):
		group_targets[0] = get_global_mouse_position()
		targetMarker.global_position = group_targets[0]
		for m in group[0]:
			if m.selected:
				m.dest = group_targets[0]
				m.selected = false
			
	elif Input.is_action_just_pressed("select"):
		var hit = false
		for m in group[0]:
			if m.hasMouse():
				m.selected = true
				hit = true
		if hit == false:
			for m in group[0]:
				m.selected = false
				
			
	
