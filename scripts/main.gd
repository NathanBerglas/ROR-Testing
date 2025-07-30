extends Node

@export var playerScene: PackedScene
var time = 0
var playerName = "hello"
var m = null
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
	if multiplayer.get_unique_id() != 1:
		for p in GameManager.Players:
			if p == multiplayer.get_unique_id():
				if GameManager.ownControllersSet == true:
					UpdatePlayerInfo.rpc_id(1, playerName, multiplayer.get_unique_id(), GameManager.Players[p].controllers)
	else:
		if GameManager.controllersSet == false:
			var allSet = true
			for p in GameManager.Players:
				if GameManager.Players[p].controllers.size() == 0:
					allSet = false
			if allSet:
				GameManager.controllersSet = true

@rpc("any_peer")
func UpdatePlayerInfo(name, id,controllers):

	for p in GameManager.Players:
		if p == id:
			GameManager.Players[p].controllers = controllers
	
	if multiplayer.get_unique_id() == 1:
		for i in GameManager.Players:
			UpdatePlayerInfo.rpc(GameManager.Players[i].name, i,GameManager.Players[i].controllers)
