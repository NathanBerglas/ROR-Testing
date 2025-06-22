extends Node2D

@export var meeple_prefab: PackedScene

func _process(delta):
	if Input.is_action_just_pressed("spawn_meeple"):
		var instance = meeple_prefab.instantiate()
		instance.global_position = get_global_mouse_position()
		add_child(instance)
		print("Spawned meeple")
