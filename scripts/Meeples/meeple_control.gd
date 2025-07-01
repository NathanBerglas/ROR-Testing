extends Node2D

@export var targetMarker: Sprite2D
@export var meeple_prefab: PackedScene
@onready var selection_box = $ColorRect
@onready var RCLICKORDER = $"Rightclick Menu/VBoxContainer/Order"
@onready var RCLICKGROUP = $"Rightclick Menu/VBoxContainer/Group"
@onready var RCLICKMENU = $"Rightclick Menu/VBoxContainer"
var group: Array[Array] = [[]]
var group_targets: Array[Vector2] = [Vector2(1000,500)]
var teammates = []

var selecting = Vector2(0,0)
var selectingTime = 0

func _ready() -> void:
	selection_box.visible = false
	RCLICKMENU.visible = false
	
	RCLICKGROUP.button_down.connect(_on_group_button_pressed)
	RCLICKGROUP.button_up.connect(_on_group_button_released)

	
	RCLICKORDER.button_down.connect(_on_order_button_pressed)
	RCLICKORDER.button_up.connect(_on_order_button_released)
	
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
			
			
	elif Input.is_action_just_pressed("right_click_menu"):
		RCLICKMENU.set_global_position(get_global_mouse_position())
		RCLICKMENU.visible = true
		
	elif Input.is_action_just_pressed("select") and teammates[0].buildingDraggin == null:
		RCLICKMENU.visible = false
		selecting = get_global_mouse_position()
		selectingTime = 0
		
	elif Input.is_action_pressed("select") and teammates[0].buildingDraggin == null:
		selectingTime += delta
		if selectingTime > 0.5:
			selection_box.visible = true
			update_selection_box()

	elif Input.is_action_just_released("select"):
		selectingTime += delta
		if selectingTime < 0.5:
			var hit = false
			
			for g in group.size():
				for m in group[g].size():
					if group[g][m].hasMouse():
						group[g][m].selected = true
						hit = true
						
						if g > 0:
							for i in group[g]:
								i.selected = true
			if hit == false:
				for g in group:
					for m in g:
						m.selected = false
		else:
			var rect = Rect2(selection_box.global_position, selection_box.size)
			for g in group.size():
				for m in group[g].size():
					if rect.has_point(group[g][m].pos):
						group[g][m].selected = true
						
						if g > 0:
							for i in group[g]:
								i.selected = true
					
					
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
func _on_order_button_pressed():
	group_targets[0] = RCLICKMENU.get_global_position()
	targetMarker.global_position = group_targets[0]
	for g in group:		
		for m in g:
			if m.selected:
				m.dest = group_targets[0]
				m.selected = false
				
func _on_order_button_released():
	RCLICKMENU.visible = false
	
func _on_group_button_pressed():
	
	group.push_back([])
	
	for g in group:
		
		var m = 0
		var cap = g.size()
		while m < cap:
			if g[m].selected == true:
				group[group.size() - 1].push_back(g.pop_at(m))
				print("Put a node in group: " + str(group.size() - 1))
				m -= 1
				cap -= 1
			m += 1
	
	removeEmptyGroups()
	print("Groups look like: " + str(group))
	for g in group:
		print(str(g.size()))
func _on_group_button_released():
	RCLICKMENU.visible 	= false
	
func removeEmptyGroups():
	var cap = group.size()
	var i = 0
	
	while i < cap:
		if i > 0 and group[i].size() <= 0:
			group.pop_at(i)
			i -= 1
			cap -= 1
		i += 1
		
