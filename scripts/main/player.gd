extends Node2D

var playerID = 0

var queued_orders_to_send_meeple: Array = [[0, []],[0, []]]
var queued_orders_recieved_meeple: Array = [[0, []],[0, []]]

var queued_orders_to_send_building: Array = [[0, []],[0, []]]
var queued_orders_recieved_building: Array = [[0, []],[0, []]]


@onready var c = []  #What nodes the player uses

@export var buildingControlScene: PackedScene
@export var meepleControlScene: PackedScene

var enemies = []


var time: float = 0
var grid: Node

const MEEPLE_Z_INDEX = 2
const BUILDING_Z_INDEX = 2


func _ready() -> void:
	
	var buildingControlC = buildingControlScene.instantiate()
	var meepleControlC = meepleControlScene.instantiate()
	meepleControlC.teammates.push_back(buildingControlC)
	buildingControlC.teammates.push_back(meepleControlC)

	meepleControlC.grid = $Grid
	buildingControlC.grid = $Grid
	meepleControlC.set_z_index(MEEPLE_Z_INDEX)
	buildingControlC.set_z_index(BUILDING_Z_INDEX)
	
	
	var buildingControlE = buildingControlScene.instantiate()
	var meepleControlE = meepleControlScene.instantiate()
	
	enemies.append(meepleControlE)
	enemies.append(buildingControlE)
	
	if multiplayer.get_unique_id() == 1:
		buildingControlC.playerID = multiplayer.get_peers()[0]
		meepleControlC.playerID = multiplayer.get_peers()[0]
		queued_orders_to_send_meeple[0][0] = multiplayer.get_peers()[0]
		queued_orders_recieved_meeple[0][0] = multiplayer.get_peers()[0]
		
		queued_orders_to_send_building[0][0] = multiplayer.get_peers()[0]
		queued_orders_recieved_building[0][0] = multiplayer.get_peers()[0]
		
		for e in enemies:
			e.playerID = multiplayer.get_peers()[1]
			queued_orders_to_send_meeple[1][0] = multiplayer.get_peers()[1]
			queued_orders_recieved_meeple[1][0] = multiplayer.get_peers()[1]
			
			queued_orders_to_send_building[1][0] = multiplayer.get_peers()[1]
			queued_orders_recieved_building[1][0] = multiplayer.get_peers()[1]
	else:
		buildingControlC.playerID = multiplayer.get_unique_id()
		meepleControlC.playerID = multiplayer.get_unique_id()
		
		queued_orders_to_send_meeple[0][0] = multiplayer.get_unique_id() 
		queued_orders_recieved_meeple[0][0] = multiplayer.get_unique_id()
		
		queued_orders_to_send_building[0][0] = multiplayer.get_unique_id() 
		queued_orders_recieved_building[0][0] = multiplayer.get_unique_id()
		var opID = 0
		if multiplayer.get_peers()[0] == 1:
			opID = multiplayer.get_peers()[1]
			
		else:
			opID = multiplayer.get_peers()[0]
		
		queued_orders_to_send_meeple[1][0] = opID
		queued_orders_recieved_meeple[1][0] = opID
		
		queued_orders_to_send_building[1][0] = opID
		queued_orders_recieved_building[1][0] = opID
		for e in enemies:
			e.playerID = opID
			
	
	
	buildingControlE.teammates.append(meepleControlE)
	meepleControlE.teammates.append(buildingControlE)

	meepleControlE.grid = $Grid
	buildingControlE.grid = $Grid
	
	c.append(meepleControlC)
	c.append(buildingControlC)
	add_child(buildingControlC)
	add_child(meepleControlC)
	
	add_child(buildingControlE)
	add_child(meepleControlE)
	$Grid.meeple_controls.append(meepleControlC)
	$Grid.meeple_controls.append(meepleControlE)
	#print(meepleControl.playerID)
	#print(buildingControl.playerID)
	#print(meepleControlC.playerID)
	#print(buildingControlC.playerID)
 
	
@rpc("any_peer")
func transfer_orders(ordersMeeple, ordersBuilding, idFrom):
	if multiplayer.get_unique_id() == idFrom:
		if multiplayer.is_server():
			transfer_orders.rpc(queued_orders_to_send_meeple, queued_orders_to_send_building, multiplayer.get_unique_id())
			queued_orders_to_send_meeple = [[queued_orders_to_send_meeple[0][0],[]],[queued_orders_to_send_meeple[1][0], []]]
			queued_orders_to_send_building = [[queued_orders_to_send_building[0][0],[]],[queued_orders_to_send_building[1][0], []]]

		else:
			print("Send help")
			breakpoint
	
	else:
		if multiplayer.is_server():
			for idArray in ordersMeeple:
				
				if idArray[0] == queued_orders_recieved_meeple[0][0]:
					queued_orders_recieved_meeple[0][1].append_array(idArray[1])
				elif idArray[0] == queued_orders_recieved_meeple[1][0]:
					queued_orders_recieved_meeple[1][1].append_array(idArray[1])
				
				
				if idArray[0] == queued_orders_to_send_meeple[0][0]:
					queued_orders_to_send_meeple[0][1].append_array(idArray[1])
				elif idArray[0] == queued_orders_recieved_meeple[1][0]:
					queued_orders_to_send_meeple[1][1].append_array(idArray[1])
			
			for idArray in ordersBuilding:
				
				if idArray[0] == queued_orders_recieved_building[0][0]:
					queued_orders_recieved_building[0][1].append_array(idArray[1])
				elif idArray[0] == queued_orders_recieved_building[1][0]:
					queued_orders_recieved_building[1][1].append_array(idArray[1])
				
				
				if idArray[0] == queued_orders_to_send_building[0][0]:
					queued_orders_to_send_building[0][1].append_array(idArray[1])
				elif idArray[0] == queued_orders_recieved_building[1][0]:
					queued_orders_to_send_building[1][1].append_array(idArray[1])
		else:
			#print("")
			#print("On multiplayer instance: " + str(playerID))
			
			for idArray in queued_orders_recieved_meeple:
				if idArray[0] == ordersMeeple[0][0]:
					idArray[1].append_array(ordersMeeple[0][1])
				else:
					idArray[1].append_array(ordersMeeple[1][1])
			
			for idArray in queued_orders_recieved_building:
				if idArray[0] == ordersBuilding[0][0]:
					idArray[1].append_array(ordersBuilding[0][1])
				else:
					idArray[1].append_array(ordersBuilding[1][1])

			transfer_orders.rpc_id(1, queued_orders_to_send_meeple, queued_orders_to_send_building, multiplayer.get_unique_id())
			queued_orders_to_send_meeple = [[queued_orders_to_send_meeple[0][0],[]],[queued_orders_to_send_meeple[1][0], []]]
			queued_orders_to_send_building = [[queued_orders_to_send_building[0][0],[]],[queued_orders_to_send_building[1][0], []]]
	pass


func _process(_delta): #Runs every tick
	#Meeple Orders
	for idArray in queued_orders_to_send_meeple:
		if idArray[0] == playerID:
			idArray[1].append_array(c[0].queued_orders_to_send_in_control)
			c[0].queued_orders_to_send_in_control = []
	for idArray in queued_orders_recieved_meeple:
		if idArray[0] == c[0].playerID:
			c[0].queued_orders_recieved_in_control.append_array(idArray[1])
			idArray[1] = []
		if idArray[0] == enemies[0].playerID:
			enemies[0].queued_orders_recieved_in_control.append_array(idArray[1])
			idArray[1] = []
	
	#Building Orders
	for idArray in queued_orders_to_send_building:
		if idArray[0] == playerID:
			idArray[1].append_array(c[1].queued_orders_to_send_in_control)
			c[1].queued_orders_to_send_in_control = []
	for idArray in queued_orders_recieved_building:
		if idArray[0] == c[1].playerID:
			c[1].queued_orders_recieved_in_control.append_array(idArray[1])
			idArray[1] = []
		if idArray[0] == enemies[1].playerID:
			enemies[1].queued_orders_recieved_in_control.append_array(idArray[1])
			idArray[1] = []
			

	if multiplayer.is_server():
		transfer_orders(queued_orders_to_send_meeple, queued_orders_to_send_building, multiplayer.get_unique_id())
	
