extends Node2D
 
const FLAG_VERBOSE = true
const FLAG_DEBUG = true
const FLAG_VERBOSE_MULTI = false

#Example Order:          [0, (2029, 19281)]

@export var targetMarker: Sprite2D
@export var infantry_prefab_team: PackedScene
@export var infantry_prefab_enemy: PackedScene


@onready var selection_box = $ColorRect
@onready var RCLICKORDER = $VBoxContainer/Merge
@onready var RCLICKGROUP = $VBoxContainer/Group
@onready var RCLICKATTACK= $VBoxContainer/Attack
@onready var RCLICKMENU = $VBoxContainer

#Multiplayer Variables
var time_print = 0
var playerID = null
var queued_orders_recieved_in_control = []
var queued_orders_to_send_in_control = []
const ORDERS = [0,1,2,3,4,5,6] #0: Spawn meeple, 1: Super Order Meeples, 2: Order Meeples, 3: Attack

const MEEPLE_TICKS_PER_SECOND = 60
var time_since_last_meeple_tick = 0
#The list of meeple groups, their targets, and their colours
var MEEPLE_ID_INDEX = 0
var MEEPLE_POS_INDEX = 1
var MEEPLE_HP_INDEX = 2

var unorderedMeeples = []
var nextGroupID = 1
var group_targets: Array[Vector2] = [Vector2(1000,500)]
var groupColours = [Color(1,0,0)]
var permGroupColour = [Color(1,0,0), Color(0,0,3), Color(0,3,0), Color(3,3,0), Color(3,0,3),Color(0,3,3)]

var selected_colour = Color(1.3, 1.3, 0.6) 

#Team mates for this player and what team they are on
var teammates = []

#The grid
var grid

#var playerID = 0
#logic used for the cool selcting box
var selecting = Vector2(0,0)
#var selectingTime = 0

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
	#RCLICKATTACK.button_down.connect(_on_attack_button_pressed)
	#RCLICKATTACK.button_up.connect(_on_attack_button_released)


func _process(delta): #Runs every tick
	if queued_orders_recieved_in_control.size() > 0:
		if FLAG_VERBOSE_MULTI: print(queued_orders_recieved_in_control)
	if queued_orders_to_send_in_control.size() > 0:
		if FLAG_VERBOSE_MULTI: print(queued_orders_to_send_in_control)
	process_orders()

	time_print += delta
	time_since_last_meeple_tick += delta
	#if playerID == multiplayer.get_unique_id():
	if time_since_last_meeple_tick > (1.0 / MEEPLE_TICKS_PER_SECOND):
		time_since_last_meeple_tick = 0
		meeple_process()
	
	if multiplayer.get_unique_id() == playerID: 
		if Input.is_action_just_pressed("spawn_meeple"): #Testing purposes
			if playerID != 1:
				queued_orders_to_send_in_control.append([0,[get_global_mouse_position()]])
			else:
				queued_orders_recieved_in_control.append([0,[get_global_mouse_position()]])

		#Orders all meeples to a location
		elif Input.is_action_just_pressed("super_order"):
			
			if playerID != 1:
				queued_orders_to_send_in_control.append([1,[get_global_mouse_position()]])
			else:
				queued_orders_recieved_in_control.append([1,[get_global_mouse_position()]])
			
		
		#Opens up the right click menu
		elif Input.is_action_just_pressed("right_click_menu"):
			if grid.probe(get_global_mouse_position()).classification == 3:
				RCLICKMENU.set_global_position(get_global_mouse_position())
				RCLICKMENU.visible = true
			elif Input.is_action_just_pressed("order"):
				RCLICKMENU.visible = false
				var selectedMeepleId = []
				for m in unorderedMeeples:
					if m.selected:
						#m.is_unselected()
						selectedMeepleId.append(m.UNIQUEID)
				if playerID != 1:
					queued_orders_to_send_in_control.append([2,[get_global_mouse_position(), selectedMeepleId]])
				else:
					queued_orders_recieved_in_control.append([2,[get_global_mouse_position(), selectedMeepleId]])

		elif Input.is_action_just_pressed("order"):
			var selectedMeepleId = []
			for m in unorderedMeeples:
				if m.selected:
					#m.is_unselected()
					selectedMeepleId.append(m.UNIQUEID)
			if playerID != 1:
				queued_orders_to_send_in_control.append([2,[get_global_mouse_position(), selectedMeepleId]])
			else:
				queued_orders_recieved_in_control.append([2,[get_global_mouse_position(), selectedMeepleId]])
		
		#Starts the selction process
		elif Input.is_action_just_pressed("select") and teammates[0].buildingDraggin == null:
			RCLICKMENU.visible = false
			selecting = get_global_mouse_position()
			if !Input.is_action_pressed("preserve_selection"):
				var clicked_meeple_hex = grid.probe(get_global_mouse_position()).hex
				for m in unorderedMeeples:
					if m.path[0] != clicked_meeple_hex:
							m.is_unselected()
				
		#Used to build the selection box if
		elif Input.is_action_pressed("select") and teammates[0].buildingDraggin == null:
			#selectingTime += delta
			#if selectingTime > 0.25:
			if InputEventMouseMotion:
				selection_box.visible = true
				update_selection_box()
				
		#Logic for when the select button is released
		elif Input.is_action_just_released("select"):
			
			#Same thing but for all meeples in the rectangle
			var rect = Rect2(selection_box.global_position, selection_box.size)
			for m in unorderedMeeples:
				if rect.has_point(m.get_global_position()):
					m.is_selected()
		
			selecting = Vector2(0, 0) #No more selecting :(
			selection_box.visible = false
			
		if Input.is_action_just_pressed("attack"):
			var attackLoc = grid.coord_to_axial_hex(get_global_mouse_position())
			var tempMeepleArray = []
			for m in unorderedMeeples:
				if m.selected:
					tempMeepleArray.append(m.UNIQUEID)
					m.is_unselected()
			if grid.axial_probe(attackLoc).objectsInside.size() > 0 and grid.axial_probe(attackLoc).objectsInside[0].playerID != playerID:
				if FLAG_VERBOSE_MULTI: print("")
				if FLAG_VERBOSE_MULTI:print("Meeple of: " + str(playerID))
				if FLAG_VERBOSE_MULTI:print("Attacking: " + str(grid.axial_probe(attackLoc).objectsInside[0].playerID))
				if FLAG_VERBOSE_MULTI:print("")
				if playerID != 1:
					queued_orders_to_send_in_control.append([3,[attackLoc, tempMeepleArray]])
				else:
					queued_orders_recieved_in_control.append([3,[attackLoc, tempMeepleArray]])
	
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


# Moves Meeples and checks if they've arrived at their destination
func _physics_process(delta: float) -> void:
	for m in unorderedMeeples:
		if !m.shouldBeMoving:
			continue
		var next_hex: Vector2 = grid.axial_hex_to_coord(m.path[1])
		var dir_to_next_hex = (next_hex - m.global_position) / (next_hex - m.global_position).length()
		var speed = 2 * m.speed / (grid.grid[m.path[0].x][m.path[0].y].traversal_difficulty + grid.grid[m.path[1].x][m.path[1].y].traversal_difficulty)
		if (next_hex - m.global_position).length() >= m.speed * delta: # Not yet arrived
			m.global_position += dir_to_next_hex * speed * delta
		else: # Just entered the hex
			m.pause_a_tick = true
			m.global_position = next_hex
			var next_hex_tile = grid.axial_probe(m.path[1])
			if (next_hex_tile.classification == 3 and next_hex_tile.objectsInside[0].playerID == m.playerID):
				if m.UNIQUEID == next_hex_tile.objectsInside[0].UNIQUEID:
					print("URGENT - Meeple ", m.UNIQUEID, " is not feeling good (self-merge)")
					if FLAG_DEBUG: breakpoint
					meeple_end_merge(m, next_hex_tile.objectsInside[0])
				else:
					if FLAG_VERBOSE: print("Meeple ", m.UNIQUEID, " has reached merge position at hex: ", m.path[1], " with meeple ", next_hex_tile.objectsInside[0].UNIQUEID)
					meeple_end_merge(m, next_hex_tile.objectsInside[0])
					freeMeeple(m.UNIQUEID)
			else:
				grid.update_grid(m.path[1], 3, [m])
				m.path.pop_front()
				#if FLAG_VERBOSE: print("Meeple ", m.UNIQUEID, " has stopped moving at position ", m.global_position, " in hex: ", next_hex)
				m.shouldBeMoving = false


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



func spawn_meeple(pos):
	var meeple_hex = grid.coord_to_axial_hex(pos)
	if grid.grid[meeple_hex.x][meeple_hex.y].classification == 3:
		grid.grid[meeple_hex.x][meeple_hex.y].objectsInside[0].update_hp(1)
		return
	var instance
	if playerID == multiplayer.get_unique_id():
		instance = infantry_prefab_team.instantiate()
	else:
		instance = infantry_prefab_enemy.instantiate()
	# Set instance's data
	instance.set_id(MEEPLE_ID_COUNTER)
	instance.playerID = playerID
	
	MEEPLE_ID_COUNTER += 1
	instance.global_position = grid.hex_center(pos)
	grid.update_grid(meeple_hex, 3, [instance])
	instance.path = [meeple_hex]
	#instance.target = group_targets[0]
	# Create instance
	add_child(instance)
	set_id(instance)
	unorderedMeeples.push_back(instance)
	if FLAG_VERBOSE: print("Spawned meeple ", instance.UNIQUEID)


#Order all the selected meeples to that place
func _on_order_button_pressed():
	RCLICKMENU.visible = false
	var selectedMeepleId = []
	for m in unorderedMeeples:
		if m.selected:
			#m.is_unselected()
			selectedMeepleId.append(m.UNIQUEID)
	if playerID != 1:
		queued_orders_to_send_in_control.append([2,[RCLICKMENU.get_global_position(), selectedMeepleId]])
	else:
		queued_orders_recieved_in_control.append([2,[RCLICKMENU.get_global_position(), selectedMeepleId]])


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
		if FLAG_VERBOSE: print("Meeple ID: " + str(m.UNIQUEID) + ", Group Number: " + str(m.groupNum))


func _on_group_button_released():
	RCLICKMENU.visible = false


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
		i += 1tempPath
"""




func set_id(node):
	node.UNIQUEID = MEEPLE_ID_COUNTER
	MEEPLE_ID_COUNTER += 1


#func get_group_targets():
#	return group_targets
#func get_groupColours():
#	return groupColours


func freeMeeple(id):
	if FLAG_VERBOSE: print("Deleting meeple ", id)
	for i in range(unorderedMeeples.size()):
		if unorderedMeeples[i].UNIQUEID == id:
			if !unorderedMeeples[i].shouldBeMoving:
				grid.update_grid(unorderedMeeples[i].path[0], 0, [])
			else:
				if !grid.axial_probe(unorderedMeeples[i].path[1]).classification == 3: # no other meeple inside
					grid.update_grid(unorderedMeeples[i].path[1], 0, [])
			unorderedMeeples.pop_at(i).queue_free()
			return

func order_meeple(coordinate, meeple_list):
	var dest = grid.hex_center(coordinate)
	#targetMarker.global_position = dest
	for m in meeple_list:
		m.attackTarget = null
		m.queued_path = grid.find_path(grid.coord_to_axial_hex(m.rb.get_global_position()), grid.coord_to_axial_hex(dest), false, false)


func meeple_start_merge(target_meeple):
	target_meeple.waiting = true
	if FLAG_VERBOSE: print("Meeple ", target_meeple.UNIQUEID, " set to waiting in meeple_start_merge.")
	

func meeple_end_merge(incoming_meeple, target_meeple):
	target_meeple.update_hp(incoming_meeple.HP)
	if !target_meeple.inqueue: 
		target_meeple.waiting = false
		# Error caused if the target meeple is currently in a queue
		if FLAG_VERBOSE: print("Meeple ", target_meeple.UNIQUEID, " set to stop waiting in meeple_end_merge.")
	else:
		if FLAG_VERBOSE: print("Meeple ", target_meeple.UNIQUEID, " in a queue, won't stop waiting in meeple_end_merge.")


func egress_granted(waiting_meeple):
	if FLAG_VERBOSE and waiting_meeple.waiting: print("Meeple ", waiting_meeple.UNIQUEID, " set to stop waiting in egress_granted.")
	waiting_meeple.waiting = false
	waiting_meeple.shouldBeMoving = true


func meeple_process():
	for m in unorderedMeeples:
		if m.pause_a_tick:
			m.pause_a_tick = false
			continue
		if (m.shouldBeMoving || m.waiting):
			continue
		if (m.attackTarget != null):
			var pos = null
			if m.attackTarget.type == "Infantry": pos = m.attackTarget.path[0]
			else: pos = m.attackTarget.pos
			if m.inAttackRange(pos):
				m.path = [m.path[0]]
				continue
		if not m.queued_path.is_empty():
			m.path = grid.find_path(m.path[0], m.queued_path[m.queued_path.size() - 1], false, false)
			#m.path = m.queued_path#.slice(1) # Remove first hex in queued path
			m.queued_path = []
		if (m.path.size() > 1):
			var ingress_result = grid.hex_ingress(m.path[1], m)
			if (ingress_result == "REDIRECTED"): # Redirected
				m.redirected_from.append(m.path[1])
				m.queued_path = grid.redirected_find_path(m.path, false, false, m.redirected_from)
			else:
				m.redirected_from = []
				if (ingress_result == "APPROVED"):
					grid.hex_egress(m.path[0])
					m.shouldBeMoving = true
					continue
				elif (ingress_result == "PENDING"):
					m.redirected_from = []
					m.waiting = true
					if FLAG_VERBOSE: print("Meeple ", m.UNIQUEID, " set to waiting due to pending ingress.")
					continue
				elif (ingress_result == "ATTACKING"):
					m.redirected_from = []
					m.attackTarget = true
					continue


""" Multiplayer Shit
func equalize(otherController):
	
	cleanNodes(otherController)
	updatePos(otherController)
	
"""
"""
func get_group():
	return group
"""


'''
func cleanNodes(meepleList):
	
	var x = 1
	if meepleList == null: return
	if meepleList.size() == 0 and unorderedMeeples.size() == 0: return
	
	while x < meepleList.size():
		if x >= unorderedMeeples.size():
			var instance = infantry_prefab.instantiate()
			
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
'''


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
'''
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
		#m.shouldBeMoving = true
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
'''


'''
func atDest(m):
	if m.path == null:
		return true
	else:
		return false
'''

'''
Meeple Move Algorithm: MMA

--------------------------------------------------
				MEEPLE_CONTROL:
--------------------------------------------------

~~~ On Every Tick: ~~~ DONE
1. Is this tick a Meeple Tick?
	Yes: Run Meeple Tick
	No: Continue

~~~ On Movement Commmand: ~~~ DONE
1. Call find_path in GRID
	Path Found: Set meeple's path to newly found path -> Continue
	Path Not Found: Break

~~~ On meeple_start_merge: ~~~ DONE
1. Set target meeple waiting flag to true -> Continue

~~~ On meeple_end_merge: ~~~ DONE
1. Increase target meeple's health by the incoming meeple's health -> Continue

~~~ On egress_granted: ~~~ DONE
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

~~~ On hex_ingress: ~~~ DONE
1. Is there an existing queue to enter this hex?
	Yes:	Add meeple to queue to enter that hex -> Return Pending
	No:		Continue
2. Is hex occupied?
	Yes: Is the hex's classification that of a meeple?
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

~~~ On hex_egress: ~~~ DONE
1. Pop meeple from hex -> Does the hex have a queue?
	Yes:	Pop a meeple out from the front of the queue -> Update grid to occupy new hex with that meeple if it
	No:		Continue
2. Call attack_target_move on enemy MEEPLE_CONTROL and pass the popped meeple -> Call egress_granted providing the meeple which egressed -> Continue

--------------------------------------------------
		For every meeple in MEEPLE_CONTROL:
--------------------------------------------------

~~~ On Every Meeple Tick: ~~~ DONE
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

~~~ On Every Physics Tick: ~~~ DONE
1. Does the meeple have the moving flag?
	Yes:	Move towards target hex -> Has the meeple arrived at the hex?
		Yes:	Continue
		No:		Break
	No: 	Break
2. Does the hex that the meeple arrived in already have another meeple?
	Yes:	Call meeple_end_merge -> Delete Self
	No: 	Pop current hex from path -> Set moving flag to false -> Break
'''


func process_orders(): #Change this to basically process as many as possible. Idk how, like funny logic
	#In addition, add logic for in the server to confirm orders are A-OK
	if queued_orders_recieved_in_control.size() > 0:
		var order = queued_orders_recieved_in_control.pop_at(0)
		
		#If statements for orders based on order - update later 
		if order[0] == 0:
			spawn_meeple_order(order[1])
		if order[0] == 1:
			super_order_order(order[1])
		if order[0] == 2:
			order_order(order[1])
		if order[0] == 3:
			attack_order(order[1])
func spawn_meeple_order(position):
	var pixel_position = position[0]
	if grid.probe(pixel_position).classification == 3:
		grid.probe(pixel_position).objectsInside[0].update_hp(1)
		return
	elif grid.probe(pixel_position).classification != 0:
		if FLAG_VERBOSE: print("Failed to place meeple. Hex obstructed")
		return
	
	spawn_meeple(pixel_position)


func super_order_order(position):
	var dest = grid.coord_to_axial_hex(position[0])
	for m in unorderedMeeples:
		if m.groupNum == 0:
			m.queued_path = grid.find_path(m.path[0], dest, true, false)



func order_order(args): #Function in O(m^2) where m is the amount of meeples. Rewrite to select on click across? Felt wierd
	var meepleList = args[1]
	var p = args[0]
	var temp_array = []

	for id in meepleList:
		for m in unorderedMeeples:
			if id == m.UNIQUEID:
				temp_array.append(m)
	order_meeple(p, temp_array)
	pass


func attack_order(args):
	var meepleList = args[1]
	var attackLoc = args[0]
	for id in meepleList:
		for m in unorderedMeeples:
			if id == m.UNIQUEID:
				#var tile = grid.axial_probe(attackLoc)
				if grid.axial_probe(attackLoc).objectsInside.size() > 0:
					# TODO Set the target of the attack to be whatever attacking location is closest to meeple, so
					# meeple can get in range of the edge of a multihex building
					if grid.axial_probe(attackLoc).objectsInside[0].playerID != playerID:
						
						m.attackTarget = grid.axial_probe(attackLoc).objectsInside[0]
						
						if FLAG_VERBOSE: print("Meeple ", m.UNIQUEID, " attacking: ", m.attackTarget)
						if !m.inAttackRange(attackLoc):
							m.queued_path = grid.find_path(grid.coord_to_axial_hex(m.rb.get_global_position()), attackLoc, true, true)
