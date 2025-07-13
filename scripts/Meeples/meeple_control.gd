extends Node2D

@export var targetMarker: Sprite2D
@export var meeple_prefab: PackedScene
@onready var selection_box = $ColorRect
@onready var RCLICKORDER = $VBoxContainer/Order
@onready var RCLICKGROUP = $VBoxContainer/Group
@onready var RCLICKMENU = $VBoxContainer
var group: Array[Array] = [[]]
var group_targets: Array[Vector2] = [Vector2(1000,500)]
var teammates = []
var groupColours = [Color(1,0,0)]
var permGroupColour = [Color.AQUA, Color.ALICE_BLUE, Color.AQUAMARINE, Color.BLUE,Color.CORNFLOWER_BLUE]
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
	
	for g in range(0,group.size()):
		for node in range(0,group[g].size()):
			if group[g][node].selected:
				group[g][node].highlight(Color(3,3,3))
			else:
				group[g][node].remove_highlight(groupColours[g])
				
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
				var n = g.pop_at(m)
				groupColours.push_back(colourNotIn())
				n.highlight(groupColours[group.size() - 1])
				group[group.size() - 1].push_back(n)
				#print("Put a node in group: " + str(group.size() - 1))
				m -= 1
				cap -= 1
			m += 1
	removeEmptyGroups()
	#print("Groups look like: " + str(group))
	for g in group:
		print(str(g.size()))
		
		
func _on_group_button_released():
	RCLICKMENU.visible 	= false
	
func removeEmptyGroups(): #Gets rid of all groups with no meeples
	var cap = group.size()
	var i = 0
	
	while i < cap:
		if i > 0 and group[i].size() <= 0:
			group.pop_at(i)
			groupColours.pop_at(i)
			i -= 1
			cap -= 1
		i += 1
		
func colourNotIn():
	print("looking for one")
	var found = false
	for c in permGroupColour:
		for nc in groupColours:
			found = false
			if c == nc:
				found = true
				break
		if found == false:
			print("Found One")
			return c
