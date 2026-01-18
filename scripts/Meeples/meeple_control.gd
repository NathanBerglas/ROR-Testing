extends Node2D

@export var targetMarker: Sprite2D
@export var meeple_prefab: PackedScene
@onready var selection_box = $ColorRect
@onready var RCLICKORDER = $VBoxContainer/Order
@onready var RCLICKGROUP = $VBoxContainer/Group
@onready var RCLICKATTACK= $VBoxContainer/Attack
@onready var RCLICKMENU = $VBoxContainer

var time = 0

#The list of meeple groups, their targets, and their colours
var MEEPLE_ID_INDEX = 0
var MEEPLE_POS_INDEX = 1
var MEEPLE_HP_INDEX = 2

var unorderedMeeples = []
var nextGroupID = 1
var group_targets: Array[Vector2] = [Vector2(1000,500)]
var groupColours = [Color(1,0,0)]
var permGroupColour = [Color(1,0,0), Color(0,0,3), Color(0,3,0), Color(3,3,0), Color(3,0,3),Color(0,3,3)]

#Team mates for this player and what team they are on
var teammates = []

#The grid
var grid

#var playerID = 0
#logic used for the cool selcting box
var selecting = Vector2(0,0)
var selectingTime = 0

var MEEPLE_ID_COUNTER = 1
func _ready() -> void:
	
	#Setting base states for the selection box and the right click menu
	selection_box.visible = false
	RCLICKMENU.visible = false
	
	#Connecting the buttons to their respective functions
	RCLICKGROUP.button_down.connect(_on_group_button_pressed)
	RCLICKGROUP.button_up.connect(_on_group_button_released)
	RCLICKORDER.button_down.connect(_on_order_button_pressed)
	RCLICKORDER.button_up.connect(_on_order_button_released)
	RCLICKATTACK.button_down.connect(_on_attack_button_pressed)
	RCLICKATTACK.button_up.connect(_on_attack_button_released)
	
func _process(delta): #Runs every tick
	time += delta
	#if playerID == multiplayer.get_unique_id():
	
	#Goes through every meeple and sets them to their colour and resets their 
	cleanMeeples()
	for g in range(0,unorderedMeeples.size()):
		if unorderedMeeples[g].selected:
			unorderedMeeples[g].highlight(Color(3,3,3))
		else:
			unorderedMeeples[g].remove_highlight(permGroupColour[unorderedMeeples[g].groupNum])
				
	if Input.is_action_just_pressed("spawn_meeple"): #Testing purposes
		var instance = meeple_prefab.instantiate()
		
	
		
		# Set instance's data
		instance.UNIQUEID = MEEPLE_ID_COUNTER
		MEEPLE_ID_COUNTER += 1
		
		instance.global_position = grid.hex_center(get_global_mouse_position())
		
		#instance.target = group_targets[0]
		
		# Create instance
		add_child(instance)
		set_id(instance)
		

		unorderedMeeples.push_back(instance)
		
		#print("Spawned meeple")
		
		
		
	#Orders all meeples to a location
	elif Input.is_action_just_pressed("super_order"):
		group_targets[0] = grid.hex_center(get_global_mouse_position())
		targetMarker.global_position = group_targets[0]
		
		for m in unorderedMeeples:
			if m.groupNum == 0:
				m.dest = group_targets[0]
			
	
	#Opens up the right click menu
	elif Input.is_action_just_pressed("right_click_menu"):
		RCLICKMENU.set_global_position(get_global_mouse_position())
		RCLICKMENU.visible = true
	
	#Starts the selction process
	elif Input.is_action_just_pressed("select") and teammates[0].buildingDraggin == null:
		RCLICKMENU.visible = false
		selecting = get_global_mouse_position()
		selectingTime = 0
	
	#Used to build the selection box if
	elif Input.is_action_pressed("select") and teammates[0].buildingDraggin == null:
		selectingTime += delta
		if selectingTime > 0.25:
			selection_box.visible = true
			update_selection_box()
	
	#Logic for when the select button is released
	elif Input.is_action_just_released("select"):
		selectingTime += delta
		if selectingTime < 0.25: #No selecting box
			var hit = false
			var groupHit = null
			#iterates through all meeples to find the clicked meeples group
			#it selects all meeples in the group
			for m in unorderedMeeples: 
				if m.hasMouse():
					hit = true
					m.selected = true
					if m.groupNum > 0:
						groupHit = m.groupNum
					break
			for m in unorderedMeeples:
				if m.groupNum == groupHit:
					m.selected = true
			if hit == false:		
				for m in unorderedMeeples:
					m.selected = false
		else:
			#Same thing but for all meeples in the rectangle
			var rect = Rect2(selection_box.global_position, selection_box.size)
			var groupsHit = []
			for m in unorderedMeeples:
				if rect.has_point(m.rb.get_global_position()):
					m.selected = true
					groupsHit.push_back(m.groupNum)
			
			for g in groupsHit: #Needs a redo -> at worst its O(n^2)
				if g == 0:
					continue
				for m in unorderedMeeples:
					if m.groupNum == g:
						m.selected = true
					
					
		selecting = false #No more selecting :(
		selection_box.visible = false
		
	"""
	else:
		var MEEPLE_CONTROL_INDEX = 0
		var BUILDING_CONTROL_INDEX = 1
		for p in GameManager.Players:
			#print(playerID)
			if p == playerID:
				if GameManager.controllersSet == true:
					equalize(GameManager.Players[p].meepleInfo)
	"""

#Updates the selction box to where the mouse is
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

#Order all the selected meeples to that place
func _on_order_button_pressed():
	group_targets[0] = grid.hex_center(RCLICKMENU.get_global_position())
	targetMarker.global_position = group_targets[0]
	for m in unorderedMeeples:
		if m.selected:
			m.dest = group_targets[0]
			m.selected = false

				
func _on_order_button_released(): #Menu gone :(
	RCLICKMENU.visible = false

#Absolutly BROKEN logic for creating groups
#For real tho, it kinda fire
func _on_group_button_pressed():
	
	var hit = false
	for m in unorderedMeeples:
		if m.selected:
			hit = true
			m.groupNum = nextGroupID
			m.highlight(permGroupColour[nextGroupID])
	if hit:
		nextGroupID += 1
	
	for m in unorderedMeeples:
		print("Meeple ID: " + str(m.UNIQUEID) + ", Group Number: " + str(m.groupNum))
		
		
func _on_group_button_released():
	RCLICKMENU.visible = false
	
#Sends the meeple to attack the hex if there is something there
func _on_attack_button_pressed():
	print()
				
func _on_attack_button_released(): #Menu gone :(
	RCLICKMENU.visible = false

"""
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

"""
func colourNotIn(): #Returns a colour for a group
	#print("looking for one")
	var found = false
	for c in permGroupColour:
		for nc in groupColours:
			found = false
			if c == nc:
				found = true
				break
		if found == false:
			#print("Found One")
			return c
	return null

func set_id(node):
	node.UNIQUEID = MEEPLE_ID_COUNTER
	MEEPLE_ID_COUNTER += 1

""" Multiplayer Shit
func equalize(otherController):
	
	cleanNodes(otherController)
	updatePos(otherController)
	
"""
"""
func get_group():
	return group
"""
func get_group_targets():
	return group_targets
func get_groupColours():
	return groupColours


func cleanNodes(meepleList):
	
	var x = 1
	if meepleList == null: return
	if meepleList.size() == 0 and unorderedMeeples.size() == 0: return
	
	while x < meepleList.size():
		if x >= unorderedMeeples.size():
			var instance = meeple_prefab.instantiate()
			
			instance.UNIQUEID = meepleList[x][MEEPLE_ID_INDEX]
			
			
			instance.global_position = meepleList[x][MEEPLE_POS_INDEX]
			
				
			add_child(instance)
			set_id(instance)
			
			var newMeepleInfo = []
			newMeepleInfo.push_back(instance.UNIQUEID)
			newMeepleInfo.push_back(instance.global_position)
			newMeepleInfo.push_back(instance.HP)
			
			unorderedMeeples.push_back(newMeepleInfo)

			
			
		elif meepleList[x][MEEPLE_ID_INDEX] != unorderedMeeples[x][MEEPLE_ID_INDEX]:
			for n in unorderedMeeples:
				if n[MEEPLE_ID_INDEX]== meepleList[x][MEEPLE_ID_INDEX]:
					remove_child(n)
			unorderedMeeples.pop_at(x)
			continue
		x += 1
	while x < unorderedMeeples.size():
		unorderedMeeples.pop_at(x)


""" Multiplayer shit
func updatePos(meepleList):
	var x = 1
	if meepleList == null: return
	while x < meepleList.size():
		unorderedMeeples[x][MEEPLE_POS_INDEX] = meepleList[x][MEEPLE_POS_INDEX]
	for g in group:
		for n in g:
			for n1 in unorderedMeeples:
				if n1[MEEPLE_ID_INDEX] == n.UNIQUEID:
					n.set_global_position(n1[MEEPLE_POS_INDEX])
"""
					
					
func cleanMeeples(): #Updates the Grid and merges meeples
	var vectorsSeen = []
	var vectorsSaved = []
	var gridVectorsSeen = []
	var found = false
	
	# This algorithim goes through each meeple, saves the vector they are in, then sets the tile a meeple moved out of to clear
	#It then sets all vectors seen to have a meeple in them in the grid
	for i in range(unorderedMeeples.size()):
		if unorderedMeeples[i].pos != grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position()):

			if grid.axial_probe(unorderedMeeples[i].pos).classification == 3:
				
				grid.update_grid(unorderedMeeples[i].pos, 0)
			unorderedMeeples[i].pos = grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position())
		gridVectorsSeen.push_back(grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position()))
	
	for v in gridVectorsSeen:
		if grid.axial_probe(v).classification == 0:
			grid.update_grid(v, 3)
			
		
	for i in range(unorderedMeeples.size()):
		
		
		
		if atDest(unorderedMeeples[i]):
			for v in vectorsSeen:
				if v == grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position()):
					vectorsSaved.push_back(grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position()))
					found = true
			if !found:
				vectorsSeen.push_back(grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position()))
			found = false
	
	for v in vectorsSaved:
		var base = null
		var n = 0
		var i = 0
		while i < (unorderedMeeples.size()):
			
			if grid.coord_to_axial_hex(unorderedMeeples[i].rb.get_global_position()) == v:
				if base == null:
					base = unorderedMeeples[i]
				else:
					n += unorderedMeeples[i].HP
					var id = unorderedMeeples[i].UNIQUEID
					freeMeeple(id)
					i -= 1
					
					
					
			i += 1
		if base != null:
			base.HP += n



	
	
func atDest(meeple):
	if meeple.dest == null:
		return true
	else:
		return false


func freeMeeple(id):
	for i in range(unorderedMeeples.size()):
		if unorderedMeeples[i].UNIQUEID == id:
			unorderedMeeples.pop_at(i).queue_free()
			return

			
			
