extends Node

const ONLINE = false
@export var Address = null
@export var port = 7999


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
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
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
	if ONLINE:
		upnp_setup()


func _on_join_button_pressed() -> void:

	peer = ENetMultiplayerPeer.new()
	if ONLINE:
		Address = $LineEdit.text
	else:
		Address = "127.0.0.1"
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


#Called on the server and all clients when someone connects
func peer_connected(id):
	if multiplayer.is_server():
		print("Server Running")
	else:
		print("Player Connected: " + str(id))


#Called on the server and all clients when someone connects
func peer_disconnected(id):
	print("Player Disconnected: " + str(id))


#Only called on clients (Send info from clients to server)
func connected_to_server():
	print("Connected to server!")
	#sendPlayerInfo.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id(),null, null)


#Only called on clients
func connection_failed():
	print("Connection failed :(")


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
		
		var ID1 = multiplayer.get_peers()[0]
		var ID2 = multiplayer.get_peers()[1]
		
		biomeGen.nexusSpawn[0].append(ID1)
		biomeGen.nexusSpawn[1].append(ID2)
		
		var biomeGenInfoToSend = []
		biomeGenInfoToSend.append(biomeGen.MAP_RESOLUTION.x)
		biomeGenInfoToSend.append(biomeGen.PIXELS_PER_TILE)
		biomeGenInfoToSend.append(biomeGen.MAP_RESOLUTION.y)
		biomeGenInfoToSend.append(biomeGen.debuggingGrid)
		biomeGenInfoToSend.append(biomeGen.map)
		biomeGenInfoToSend.append(biomeGen.nexusSpawn)
		
		start_game.rpc(biomeGenInfoToSend) # [BMAP_RESOLUTIONx, BPIXELS_PER_TILE, BMAP_RESOLUTIONy, Bdebugging_grid, Bmap]
		
	
		player.get_node("Grid").BMAP_RESOLUTIONx = biomeGenInfoToSend[0]
		player.get_node("Grid").BPIXELS_PER_TILE = biomeGenInfoToSend[1]
		player.get_node("Grid").BMAP_RESOLUTIONy = biomeGenInfoToSend[2]
		player.get_node("Grid").Bdebugging_grid = biomeGenInfoToSend[3]
		player.get_node("Grid").Bmap = biomeGenInfoToSend[4]
		player.get_node("Grid").nexusSpawn = biomeGenInfoToSend[5]
		
		
	else:
		player.get_node("Grid").BMAP_RESOLUTIONx = biomeGenInfo[0]
		player.get_node("Grid").BPIXELS_PER_TILE = biomeGenInfo[1]
		player.get_node("Grid").BMAP_RESOLUTIONy = biomeGenInfo[2]
		player.get_node("Grid").Bdebugging_grid = biomeGenInfo[3]
		player.get_node("Grid").Bmap = biomeGenInfo[4]
		player.get_node("Grid").nexusSpawn = biomeGenInfo[5]
	player.playerID = multiplayer.get_unique_id()
	add_child(player)
	
	
func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	# Delete any existing mappings first to avoid conflicts


	var map_result_udp = upnp.add_port_mapping(port, port, "MyGame", "UDP", 3600)
	print("UDP map result: ", map_result_udp)
	
	assert(map_result_udp == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP UDP Port Mapping Failed! Error %s" % map_result_udp)
		
	var map_result_tcp = upnp.add_port_mapping(port, port, "MyGame", "TCP", 3600)
	print("TCP map result: ", map_result_tcp)
	assert(map_result_tcp == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP TCP Port Mapping Failed! Error %s" % map_result_tcp)
	print("Success! Join Address: %s" % upnp.query_external_address())
