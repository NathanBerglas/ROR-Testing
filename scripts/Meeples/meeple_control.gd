extends Node2D

@export var targetMarker: Sprite2D
@export var infrantry_prefab: PackedScene
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
		var instance = infrantry_prefab.instantiate()
		
	
		
		# Set instance's data
		instance.set_id(MEEPLE_ID_COUNTER)
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
		var dest = grid.hex_center(get_global_mouse_position())
		targetMarker.global_position = dest
		
		for m in unorderedMeeples:
			if m.groupNum == 0:
				m.path = grid.find_path(m.rb.get_global_position(), dest, true, false)
			
	
	#Opens up the right click menu
	elif Input.is_action_just_pressed("right_click_menu"):
		if grid.probe(get_global_mouse_position()).objectsInside.size() < 1 or grid.probe(get_global_mouse_position()).objectsInside[0].type != "ResourceHub":
			RCLICKMENU.set_global_position(get_global_mouse_position())
			RCLICKMENU.visible = true
		else:
			RCLICKMENU.visible = false
		
	
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

func spawn_meeple(position):
	var instance = infrantry_prefab.instantiate()
	instance.UNIQUEID = MEEPLE_ID_COUNTER
	MEEPLE_ID_COUNTER += 1
	
	add_child(instance)
	set_id(instance)
	instance.set_global_position(grid.axial_hex_to_coord(position))
	unorderedMeeples.push_back(instance)
	
	
#Order all the selected meeples to that place
func _on_order_button_pressed():
	
	var dest = grid.hex_center(RCLICKMENU.get_global_position())
	targetMarker.global_position = dest
	
	for m in unorderedMeeples:
		if m.selected:
			var tempPath = grid.find_path(grid.coord_to_axial_hex(m.rb.get_global_position()), grid.coord_to_axial_hex(dest), false, false)
			m.path = []
			for h in tempPath:
				m.path.append(grid.axial_hex_to_coord(h))
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
			m.highlight(permGroupColour[nextGroupID], m.sprite)
	if hit:
		nextGroupID += 1
	
	for m in unorderedMeeples:
		print("Meeple ID: " + str(m.UNIQUEID) + ", Group Number: " + str(m.groupNum))
		
		
func _on_group_button_released():
	RCLICKMENU.visible = false
	
#Sends the meeple to attack the hex if there is something there
func _on_attack_button_pressed():
	var attackLoc = grid.coord_to_axial_hex(RCLICKMENU.get_global_position())
	
	for m in unorderedMeeples:
		if m.selected:
			var tile = grid.axial_probe(attackLoc)
			if grid.axial_probe(attackLoc).objectsInside.size() > 0:
				m.attackTarget = grid.axial_probe(attackLoc).objectsInside[0]
				var tempPath = grid.find_path(grid.coord_to_axial_hex(m.rb.get_global_position()), attackLoc, true, true)
				m.path = []
				for h in tempPath:
					m.path.append(grid.axial_hex_to_coord(h))
				
				#m.dest = grid.hex_center(attackLoc)
			m.selected = false
	
	
				
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
			var instance = infrantry_prefab.instantiate()
			
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
	for m in unorderedMeeples:
		
		if m.path == null and m.attackTarget != null and !m.inAttackRange(m.attackTarget.pos):
			var tempPath = grid.find_path(grid.coord_to_axial_hex(m.rb.get_global_position()), m.attackTarget.pos, true, true)
			m.path = []
			for h in tempPath:
				m.path.append(grid.axial_hex_to_coord(h))
		if m.HP <= 0:
			
			freeMeeple(m.UNIQUEID)
	# This algorithim goes through each meeple, saves the vector they are in, then sets the tile a meeple moved out of to clear
	#It then sets all vectors seen to have a meeple in them in the grid
	for m in unorderedMeeples:
		m.shouldBeMoving = true
		if m.path:
			for i in range (m.path.size()):
			
				if (grid.probe(m.path[i]).classification == 2  or (grid.probe(m.path[i]).classification == 3 and i != m.path.size() - 1)):
					#if grid.probe(m.path[i]).classification == 3 and i == 0:
					#	if grid.probe(m.path[i]).objectsInside[0].path:
						#	m.shouldBeMoving = false
						#	break
					var tempPath = grid.find_path(m.pos, grid.coord_to_axial_hex(m.path[m.path.size() - 1]), false, false)
					m.path = []
					for h in tempPath:
						m.path.append(grid.axial_hex_to_coord(h))
					break
		if m.pos != grid.coord_to_axial_hex(m.rb.get_global_position()):
			
			
			if grid.axial_probe(m.pos).classification == 3:
				grid.update_grid(m.pos, 0, [])
		
			m.pos = grid.coord_to_axial_hex(m.rb.get_global_position())
		grid.update_grid(m.pos, 3, [m])
		gridVectorsSeen.push_back(m.pos)
			
		
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
	if meeple.path == null:
		return true
	else:
		return false


func freeMeeple(id):
	
	for i in range(unorderedMeeples.size()):
		if unorderedMeeples[i].UNIQUEID == id:
			unorderedMeeples.pop_at(i).queue_free()
			return

'''
Meeple Move Algorithm: MMA (Without attacking)

--------------------------------------------------
				MEEPLE_CONTROL:
--------------------------------------------------

~~~ On Every Tick: ~~~
1. Is this tick a Meeple Tick?
	Yes: Run Meeple Tick
	No: Continue

~~~ On Movement Commmand: ~~~
1. Call find_path in GRID
	Path Found: Set meeple's path to newly found path -> Continue
	Path Not Found: Break

~~~ On meeple_start_merge: ~~~
1. Set target meeple waiting flag to true -> Continue

~~~ On meeple_end_merge: ~~~
1. Increase target meeple's health by the incoming meeple's health -> Continue

~~~ On egress_granted: ~~~
1. Set meeple's waiting flag to false -> Set meeple's flag moving to true -> Continue

~~~ On attack_target_move: ~~~
1. For each meeple M_i:
	Is M_i attacking the moving meeple?
		Yes: 	Continue
		No: 	Break
2. Does this meeple have attack move?
	Yes:	Call On Movement Command to adjacent hex to meeple's new hex
	No: 	Remove meeple attack target

--------------------------------------------------
				GRID:
--------------------------------------------------

~~~ On hex_ingress: ~~~
1. Is there an existing queue to enter this hex?
	Yes:	Add meeple to queue to enter that hex -> Return Approved
	No:		Continue
2. Is hex occupied?
	Yes: Is the hex's classificatReturnion that of a meeple?
		Yes: 	Continue
		No:		Return Redirected
	No: 	Update grid to occupy new hex -> Return Approved
4. What team is the meeple in the new hex?
	Meeple's Team:	Continue
	Enemy Team:		Return Attacking
4. Is the final hex of the path of the meeple that is requesting ingress the same as the final hex of the path of meeple in the hex?
	Yes: 	Call meeple_start_merge -> Return Approved
	No: 	Continue
3. Does the meeple in this hex have a path?
	Yes:	Add meeple to queue to enter that hex -> Return Pending
	No:		Return Redirected

~~~ On hex_egress: ~~~
1. Pop meeple from hex -> Does the hex have a queue?
	Yes:	Pop a meeple out from the front of the queue -> Update grid to occupy new hex with that meeple if it
	No:		Continue
2. Call attack_target_move on enemy MEEPLE_CONTROL and pass the popped meeple -> Call egress_granted providing the meeple which egressed -> Continue

--------------------------------------------------
				MEEPLE:
--------------------------------------------------

~~~ On Every Meeple Tick: ~~~
1. Does the meeple have the moving flag, waiting flag, or attack target?
	Yes: 	Break
	No: 	Continue
2. Check if the meeple has path / next hex to travel to?:
	Yes: Call hex_ingress in GRID on new hex
		Approved:	Call hex_egress -> Set flag moving to true -> Break
		Pending:	Set flag waiting to true -> Break
		Redirected: Call find_path in GRID -> Update Meeple path to new path -> Call hex_ingress in GRID on new hex -> Break
		Attacking: 	Set attack target to meeple in the new hex
	No: 	Continue

~~~ On Every Physics Tick: ~~~
1. Does the meeple have the moving flag?
	Yes:	Move towards target hex -> Has the meeple arrived at the hex?
		Yes:	Continue
		No:		Break
	No: 	Break
2. Does the hex that the meeple arrived in already have another meeple?
	Yes:	Call meeple_end_merge -> Delete Self
	No: 	Pop current hex from path -> Set moving flag to false -> Break
'''
