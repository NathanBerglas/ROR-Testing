extends Node

const ONLINE = false
const SINGLE_TESTING = false
const FLAG_VERBOSE = true

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
var playerName = "PlayerName"
var m = null
var ableToSend = true
var orderNum = 0

var MAX_PLAYERS_AND_SERVER = 2
var peer

func _ready():
	if !SINGLE_TESTING:
		multiplayer.peer_connected.connect(peer_connected)
		multiplayer.peer_disconnected.connect(peer_disconnected)
		multiplayer.connected_to_server.connect(connected_to_server)
		multiplayer.connection_failed.connect(connection_failed)
		multiplayer.server_disconnected.connect(server_disconnected)
		hostButton.button_down.connect(_on_host_button_pressed)
		joinButton.button_down.connect(_on_join_button_pressed)
		startButton.button_down.connect(_on_start_button_pressed)
	
	else:
		player = playerScene.instantiate()
		player.SINGLE = SINGLE_TESTING
		biomeGen = biomeGenScene.instantiate()
		biomeGen.terrainOffset = player.get_node("Grid").terrainOffset
		biomeGen.grid = player.get_node("Grid")
		hostButton.queue_free()
		joinButton.queue_free()
		startButton.queue_free()
		labelEdit.queue_free()
		nameLabel.queue_free()
		waitingLabel.queue_free()
		var ID1 = 1
		add_child(biomeGen)
		biomeGen.nexusSpawn[0].append(ID1)
		
		@warning_ignore("unused_variable")
		var instance = biomeGenScene.instantiate()
		var biomeGenInfoToSend = []
		biomeGenInfoToSend.append(biomeGen.MAP_RESOLUTION.x)
		biomeGenInfoToSend.append(biomeGen.PIXELS_PER_TILE)
		biomeGenInfoToSend.append(biomeGen.MAP_RESOLUTION.y)
		biomeGenInfoToSend.append(biomeGen.debuggingGrid)
		biomeGenInfoToSend.append(biomeGen.map)
		biomeGenInfoToSend.append(biomeGen.nexusSpawn)
		
		
		player.get_node("Grid").BMAP_RESOLUTIONx = biomeGenInfoToSend[0]
		player.get_node("Grid").BPIXELS_PER_TILE = biomeGenInfoToSend[1]
		player.get_node("Grid").BMAP_RESOLUTIONy = biomeGenInfoToSend[2]
		player.get_node("Grid").Bdebugging_grid = biomeGenInfoToSend[3]
		player.get_node("Grid").Bmap = biomeGenInfoToSend[4]
		player.get_node("Grid").nexusSpawn = biomeGenInfoToSend[5]
		
		player.player_id = multiplayer.get_unique_id()
		add_child(player)


#If its a client, it sends its info to the server
#If it is the server, it sends the server info to all the clients
@rpc("any_peer")
func UpdatePlayerInfo(player_name, id, c, o):
	#if FLAG_VERBOSE: print("Shipment of " + str(c.size()) + " has been complete from id: " + str(id) + " to: " + str(multiplayer.get_unique_id()))
	#if FLAG_VERBOSE: print("Under order number: " + str(o))
	readySend.rpc_id(id)
	for p in GameManager.Players:
		if p == id:
			GameManager.Players[p].meepleInfo = c
			#if c.size() > 0:
				#if FLAG_VERBOSE: print("Beep boop bap: vew vew pew, meeple transfer COMPLETE")
	if multiplayer.is_server():
		for i in GameManager.Players:
			if i != id:
				UpdatePlayerInfo.rpc_id(i, GameManager.Players[id].player_name, id,c, o)


@rpc("any_peer")
func readySend():
	
	ableToSend = true


func _on_host_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS_AND_SERVER)
	if error != OK:
		if FLAG_VERBOSE: print("Cannot Host: " + str(error))
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
		if FLAG_VERBOSE: print("Bad Host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	waitingLabel.text = "WAITING ON HOST"
	waitingLabel.visible = true


func _on_start_button_pressed() -> void:
	if multiplayer.is_server() and multiplayer.get_peers().size() == MAX_PLAYERS_AND_SERVER:
		start_game(null)
	return


#Called on the server and all clients when someone connects
func peer_connected(id):
	if multiplayer.is_server():
		if FLAG_VERBOSE: print("Server Running")
	else:
		if FLAG_VERBOSE: print("Player Connected: " + str(id))


#Called on the server and all clients when someone connects
func peer_disconnected(id):
	if FLAG_VERBOSE: print("Player Disconnected: " + str(id))


#Only called on clients (Send info from clients to server)
func connected_to_server():
	if FLAG_VERBOSE: print("Connected to server!")
	#sendPlayerInfo.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id(),null, null)


#Only called on clients
func connection_failed():
	if FLAG_VERBOSE: print("Connection failed :(")

func server_disconnected():
	if FLAG_VERBOSE: print("Server Disconnected")

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
		#if FLAG_VERBOSE: print(player.get_child_count())
		
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
	player.player_id = multiplayer.get_unique_id()
	
	player.SINGLE = SINGLE_TESTING
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
	if FLAG_VERBOSE: print("UDP map result: ", map_result_udp)
	
	assert(map_result_udp == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP UDP Port Mapping Failed! Error %s" % map_result_udp)
		
	var map_result_tcp = upnp.add_port_mapping(port, port, "MyGame", "TCP", 3600)
	if FLAG_VERBOSE: print("TCP map result: ", map_result_tcp)
	assert(map_result_tcp == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP TCP Port Mapping Failed! Error %s" % map_result_tcp)
	if FLAG_VERBOSE: print("Success! Join Address: %s" % upnp.query_external_address())
