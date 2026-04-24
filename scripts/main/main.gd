extends Node

@export var Address = "127.0.0.1"
@export var port = 8910


@export var playerScene: PackedScene
var player = null
@export var biomeGenScene: PackedScene
var biomeGen = null


@onready var hostButton = $Host
@onready var nameLabel = $nameLabel
@onready var joinButton = $Join
@onready var labelEdit = $LineEdit
@onready var startButton = $Start

@onready var waitingLabel = $waitingLabel

var time = 0
var playerName = "hello"
var m = null
var ableToSend = true
var orderNum = 0

var MAX_PLAYERS_AND_SERVER = 2
var peer

func _ready():
	hostButton.button_down.connect(_on_host_button_pressed)
	joinButton.button_down.connect(_on_join_button_pressed)
	startButton.button_down.connect(_on_start_button_pressed)
	
	#multiplayer.allow_object_decoding = true
	#var index = 0
	#for i in GameManager.Players:
		#var currentPlayer = playerScene.instantiate()
		#add_child(currentPlayer)
		#currentPlayer.name = str(GameManager.Players[i].id)
		#currentPlayer.playerID = GameManager.Players[i].id
		#for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoints"):
			#if spawn.name == str(index):
				#currentPlayer.global_position = spawn.global_position
		#index += 1
	pass


func _process(delta): #runs every
	pass
	#time += delta
	#if time >= (1/60):
		#if !multiplayer.is_server():
			#for p in GameManager.Players:
				#if p == multiplayer.get_unique_id():
					#if GameManager.ownControllersSet == true and ableToSend == true:
						##print("Order " + str(orderNum) + "? DONT WORRY BOSS, I BE SENDIN INFO OF " + str(GameManager.Players[p].meepleInfo.size()) + " MEEPLES FROM " + str(p))
						#UpdatePlayerInfo.rpc_id(1, playerName, multiplayer.get_unique_id(), GameManager.Players[p].meepleInfo, orderNum)
						#ableToSend = false
						#orderNum += 1
		#if GameManager.controllersSet == false:
			#var allSet = true
			#for p in GameManager.Players:
				#if GameManager.Players[p].meepleInfo != null:
					#allSet = false
			#if allSet:
				#GameManager.controllersSet = true
		#time = 0


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


func _on_host_button_pressed() -> void:
	var MAX_PLAYERS_AND_SERVER = 3
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS_AND_SERVER)
	
	if error != OK:
		print("Cannot Host: " + str(error))
		return
	#Reduces bandwith through magic bandwith reduction software
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	waitingLabel.text = "WAITING FOR PLAYERS"
	waitingLabel.visible = true


func _on_join_button_pressed() -> void:

	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Address, port)
	
	if error != OK:
		print("Bad Host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	waitingLabel.text = "WAITING ON HOST"
	waitingLabel.visible = true


func _on_start_button_pressed() -> void:
	if multiplayer.is_server() and multiplayer.get_peers().size() == MAX_PLAYERS_AND_SERVER:
		start_game(null)
	return
	pass # Replace with function body.


@rpc("authority")
func start_game(biomeGenInfo): # [BMAP_RESOLUTIONx, BPIXELS_PER_TILE, BMAP_RESOLUTIONy, Bdebugging_grid = null, Bmap]
	hostButton.queue_free()
	joinButton.queue_free()
	startButton.queue_free()
	labelEdit.queue_free()
	nameLabel.queue_free()
	waitingLabel.queue_free()
	
	player = playerScene.instantiate()
	if multiplayer.is_server():
		#print(player.get_child_count())
		
		biomeGen = biomeGenScene.instantiate()
		
		biomeGen.terrainOffset = player.get_node("Grid").terrainOffset
		biomeGen.grid = player.get_node("Grid")
		add_child(biomeGen)
		var biomeGenInfoToSend = []
		biomeGenInfoToSend.append(biomeGen.MAP_RESOLUTION.x)
		biomeGenInfoToSend.append(biomeGen.PIXELS_PER_TILE)
		biomeGenInfoToSend.append(biomeGen.MAP_RESOLUTION.y)
		biomeGenInfoToSend.append(biomeGen.debuggingGrid)
		biomeGenInfoToSend.append(biomeGen.map)
		
		start_game.rpc(biomeGenInfoToSend) # [BMAP_RESOLUTIONx, BPIXELS_PER_TILE, BMAP_RESOLUTIONy, Bdebugging_grid, Bmap]
		
		player.get_node("Grid").BMAP_RESOLUTIONx = biomeGenInfoToSend[0]
		player.get_node("Grid").BPIXELS_PER_TILE = biomeGenInfoToSend[1]
		player.get_node("Grid").BMAP_RESOLUTIONy = biomeGenInfoToSend[2]
		player.get_node("Grid").Bdebugging_grid = biomeGenInfoToSend[3]
		player.get_node("Grid").Bmap = biomeGenInfoToSend[4]
	else:
		player.get_node("Grid").BMAP_RESOLUTIONx = biomeGenInfo[0]
		player.get_node("Grid").BPIXELS_PER_TILE = biomeGenInfo[1]
		player.get_node("Grid").BMAP_RESOLUTIONy = biomeGenInfo[2]
		player.get_node("Grid").Bdebugging_grid = biomeGenInfo[3]
		player.get_node("Grid").Bmap = biomeGenInfo[4]
	player.playerID = multiplayer.get_unique_id()
	add_child(player)
