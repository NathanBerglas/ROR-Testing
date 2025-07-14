extends Node

@export var playerScene: PackedScene

func _ready():
	
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = playerScene.instantiate()

		currentPlayer.name = str(GameManager.Players[i].id)
		currentPlayer.playerID = GameManager.Players[i].id
		GameManager.Players[i].controllers.push_back($Player/BuildingControl)
		GameManager.Players[i].controllers.push_back($Player/MeepleControl)
		print("Added controllers")
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoints"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
		index += 1
			
	
	pass

func _process(_delta): #runs every
	var x = 0
	#We vibin
