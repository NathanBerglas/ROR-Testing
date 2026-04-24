extends Node2D

var playerID = 0
var queued_orders_to_send_meeple: Array = [[0, []],[0, []]]
var queued_orders_recieved_meeple: Array = [[0, []],[0, []]]
@onready var c = [$MeepleControl, $BuildingControl]  #What nodes the player uses

@export var buildingControlScene: PackedScene
@export var meepleControlScene: PackedScene

var enemies = []


var time: float = 0
var grid: Node

const MEEPLE_Z_INDEX = 2
const BUILDING_Z_INDEX = 2


func _ready() -> void:
	$MeepleControl.teammates.push_back($BuildingControl)
	$BuildingControl.teammates.push_back($MeepleControl)

	$MeepleControl.grid = $Grid
	$BuildingControl.grid = $Grid
	$MeepleControl.set_z_index(MEEPLE_Z_INDEX)
	$BuildingControl.set_z_index(BUILDING_Z_INDEX)
	$BuildingControl/buildingHud.visible = true
	
	var buildingControl = buildingControlScene.instantiate()
	var meepleControl = meepleControlScene.instantiate()
	
	enemies.append(meepleControl)
	enemies.append(buildingControl)
	
	if multiplayer.get_unique_id() == 1:
		$BuildingControl.playerID = multiplayer.get_peers()[0]
		$MeepleControl.playerID = multiplayer.get_peers()[0]
		queued_orders_to_send_meeple[0][0] = multiplayer.get_peers()[0]
		queued_orders_recieved_meeple[0][0] = multiplayer.get_peers()[0]
		
		for e in enemies:
			e.playerID = multiplayer.get_peers()[1]
			queued_orders_to_send_meeple[1][0] = multiplayer.get_peers()[1]
			queued_orders_recieved_meeple[1][0] = multiplayer.get_peers()[1]
	else:
		$BuildingControl.playerID = multiplayer.get_unique_id()
		$MeepleControl.playerID = multiplayer.get_unique_id()
		queued_orders_to_send_meeple[0][0] = multiplayer.get_unique_id() 
		queued_orders_recieved_meeple[0][0] = multiplayer.get_unique_id()
		var opID = 0
		if multiplayer.get_peers()[0] == 1:
			opID = multiplayer.get_peers()[1]
			
		else:
			opID = multiplayer.get_peers()[0]
		
		queued_orders_to_send_meeple[1][0] = opID
		queued_orders_recieved_meeple[1][0] = opID
		for e in enemies:
			e.playerID = opID
			
	
	
	buildingControl.teammates.append(meepleControl)
	meepleControl.teammates.append(buildingControl)

	meepleControl.grid = $Grid
	buildingControl.grid = $Grid
	
	add_child(buildingControl)
	add_child(meepleControl)
	
	#print(meepleControl.playerID)
	#print(buildingControl.playerID)
	#print($MeepleControl.playerID)
	#print($BuildingControl.playerID)
 
	print()
	print(queued_orders_recieved_meeple)
	print(queued_orders_to_send_meeple)
@rpc("any_peer")
func transfer_orders(orders, idFrom):
	if multiplayer.get_unique_id() == idFrom:
		if multiplayer.is_server():
			transfer_orders.rpc(queued_orders_to_send_meeple, multiplayer.get_unique_id())
			queued_orders_to_send_meeple = [[queued_orders_to_send_meeple[0][0],[]],[queued_orders_to_send_meeple[1][0], []]]
		else:
			print("Send help")
			breakpoint
	else:
		if multiplayer.is_server():
			for idArray in orders:
				
				if idArray[0] == queued_orders_recieved_meeple[0][0]:
					queued_orders_recieved_meeple[0][1].append_array(idArray[1])
				elif idArray[0] == queued_orders_recieved_meeple[1][0]:
					queued_orders_recieved_meeple[1][1].append_array(idArray[1])
				
				
				if idArray[0] == queued_orders_to_send_meeple[0][0]:
					queued_orders_to_send_meeple[0][1].append_array(idArray[1])
				elif idArray[0] == queued_orders_recieved_meeple[1][0]:
					queued_orders_to_send_meeple[1][1].append_array(idArray[1])
		else:
			#print("")
			#print("On multiplayer instance: " + str(playerID))
			
			for idArray in queued_orders_recieved_meeple:
				
				if idArray[0] == orders[0][0]:
					idArray[1].append_array(orders[0][1])
				else:
					idArray[1].append_array(orders[1][1])
			

			transfer_orders.rpc_id(1, queued_orders_to_send_meeple, multiplayer.get_unique_id())
			queued_orders_to_send_meeple = [[queued_orders_to_send_meeple[0][0],[]],[queued_orders_to_send_meeple[1][0], []]]
	pass


func _process(_delta): #Runs every tick
	
	#print("")
	for idArray in queued_orders_to_send_meeple:
		if idArray[0] == playerID:
			idArray[1].append_array(c[0].queued_orders_to_send_in_control)
			c[0].queued_orders_to_send_in_control = []
			#print("Assigned send to of: " + str(idArray[0]))
	#print("Assigned to send In: " + str(multiplayer.get_unique_id()))
			
	for idArray in queued_orders_recieved_meeple:
		if idArray[0] == c[0].playerID:
			c[0].queued_orders_recieved_in_control.append_array(idArray[1])
			idArray[1] = []
			#print("Assigned recieved of: " + str(idArray[0]))
		if idArray[0] == enemies[0].playerID:
			enemies[0].queued_orders_recieved_in_control.append_array(idArray[1])
			idArray[1] = []
			#print("Assigned recieved of: " + str(idArray[0]))
	#print("Assigned recieved of: " + str(multiplayer.get_unique_id()))
	
	#print("")

	if multiplayer.is_server():
		transfer_orders(queued_orders_to_send_meeple, multiplayer.get_unique_id())
	
