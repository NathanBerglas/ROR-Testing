extends Node

@export var playerScene: PackedScene

func _ready():
	
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = playerScene.instantiate()
		
		add_child(currentPlayer)
		
		currentPlayer.name = str(GameManager.Players[i].id)
		currentPlayer.playerID = GameManager.Players[i].id
		
		GameManager.Players[i].controllers.push_back(currentPlayer.c[0])
		GameManager.Players[i].controllers.push_back(currentPlayer.c[1])
		
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoints"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
		index += 1
			
	
	pass

func _process(_delta): #runs every
	#We as the kids say: are no longer vibin
	for p in GameManager.Players:
		if p == 1:
			print("Hi")
	
