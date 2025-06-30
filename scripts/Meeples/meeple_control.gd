extends Node2D

@export var targetMarker: Sprite2D
@export var meeple_prefab: PackedScene
@onready var selection_box = $ColorRect


var group: Array[Array] = [[]]
var group_targets: Array[Vector2] = [Vector2(1000,500)]
var teammates = []

var selecting = Vector2(0,0)
var selectingTime = 0

func _ready() -> void:
	selection_box.visible = false
	
	
	
func _process(delta):
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
			
	elif Input.is_action_just_pressed("select") and teammates[0].buildingDraggin == null:
		selecting = get_global_mouse_position()
		selectingTime = 0
		#var hit = false
		#for m in group[0]:
			#if m.hasMouse():
				#m.selected = true
				#hit = true
		#if hit == false:
			#for m in group[0]:
				#m.selected = false
				
			
	elif Input.is_action_pressed("select") and teammates[0].buildingDraggin == null:
		selectingTime += delta
		if selectingTime > 0.5:
			selection_box.visible = true
			update_selection_box()

	elif Input.is_action_just_released("select"):
		if selectingTime < 0.5:
			var hit = false
			for m in group[0]:
				if m.hasMouse():
					m.selected = true
					hit = true
			if hit == false:
				for m in group[0]:
					m.selected = false
		else:
			var rect = Rect2(selection_box.global_position, selection_box.size)

			for m in group[0]:
				if rect.has_point(m.global_position):
					m.selected = true
					
					
		selecting = false
		selection_box.visible = false
		
		
func update_selection_box():
	var top_left = selecting
	var size = (get_global_mouse_position() - top_left).abs()
	if (get_global_mouse_position() - selecting).x < 0 and (get_global_mouse_position() - selecting).y < 0:
		top_left -= size
	elif (get_global_mouse_position() - selecting).x < 0 and (get_global_mouse_position() - selecting).y > 0:
		top_left.x -= size.x
	elif (get_global_mouse_position() - selecting).x > 0 and (get_global_mouse_position() - selecting).y < 0:
		top_left.y -= size.y
		
	selection_box.global_position = top_left
	selection_box.size = size
