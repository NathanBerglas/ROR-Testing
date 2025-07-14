extends Control

@export var Address = "127.0.0.1"
@export var port = 8910

var peer
var testTime = 0
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
func _process(delta):
	pass

#Called on the server and all clients when someone connects
func peer_connected(id):
	print("Player Connected: " + str(id))
	
	
#Called on the server and all clients when someone connects
func peer_disconnected(id):
	
	print("Player Disconnected: " + str(id))

#Only called on clients (Send info from clients to server)
func connected_to_server():
	print("Connected to server!")
	sendPlayerInfo.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id(),[])

#Only called on clients
func connection_failed():
	print("Connection failed :(")
	
@rpc("any_peer")
func sendPlayerInfo(name,id,controllers):
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"name" : name,
			"id" : id,
			"controllers" : controllers
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			sendPlayerInfo.rpc(GameManager.Players[i].name, i)
	
@rpc("any_peer","call_local")
func StartGame():
	print("Starting Game!")
	var scene = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_host_button_down() -> void:
	var MAX_PLAYERS = 2
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		print("Cannot Host: " + str(error))
		return
		
	#Reduces bandwith through magic bandwith reduction software
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players")
	sendPlayerInfo($LineEdit.text, multiplayer.get_unique_id(),[])


func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)


func _on_start_button_down() -> void:
	StartGame.rpc()
	pass # Replace with function body.
