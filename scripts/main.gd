extends Node

@export var playerScene: PackedScene
var time = 0
var playerName = "hello"
var m = null
var ableToSend = true
var orderNum = 0

func _ready():
	multiplayer.allow_object_decoding = true
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = playerScene.instantiate()
		
		add_child(currentPlayer)
		
		currentPlayer.name = str(GameManager.Players[i].id)
		currentPlayer.playerID = GameManager.Players[i].id
		
		
		
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoints"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
		index += 1
			
	
	pass

func _process(delta): #runs every
	time += delta
	if time >= (1/60):
		
		if !multiplayer.is_server():
			for p in GameManager.Players:
				if p == multiplayer.get_unique_id():
					if GameManager.ownControllersSet == true and ableToSend == true:
						#print("Order " + str(orderNum) + "? DONT WORRY BOSS, I BE SENDIN INFO OF " + str(GameManager.Players[p].meepleInfo.size()) + " MEEPLES FROM " + str(p))
						UpdatePlayerInfo.rpc_id(1, playerName, multiplayer.get_unique_id(), GameManager.Players[p].meepleInfo, orderNum)
						ableToSend = false
						orderNum += 1
		
		if GameManager.controllersSet == false:
			var allSet = true
			for p in GameManager.Players:
				if GameManager.Players[p].meepleInfo != null:
					allSet = false
			if allSet:
				GameManager.controllersSet = true
		time = 0

#If its a client, it sends its info to the server
#If it is the server, it sends the server info to all the clients
@rpc("any_peer")
func UpdatePlayerInfo(name, id, c, o):
	#print("Shipment of " + str(c.size()) + " has been complete from id: " + str(id) + " to: " + str(multiplayer.get_unique_id()))
	#print("Under order number: " + str(o))
	readySend.rpc_id(id)
	for p in GameManager.Players:
		if p == id:
			GameManager.Players[p].meepleInfo = c
			#if c.size() > 0:
				#print("Beep boop bap: vew vew pew, meeple transfer COMPLETE")
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			if i != id:
				UpdatePlayerInfo.rpc_id(i, GameManager.Players[id].name, id,c, o)


@rpc("any_peer")
func readySend():
	ableToSend = true
