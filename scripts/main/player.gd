extends Node2D

var playerID = 0
@onready var c = [$MeepleControl, $BuildingControl]  #What nodes the player uses

@export var buildingControlScene: PackedScene
@export var meepleControlScene: PackedScene

var enemies = []

var setShit = false
var time = 0
var grid

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
	
	enemies.append(buildingControl)
	enemies.append(meepleControl)
	if multiplayer.get_unique_id() == 1:
		$BuildingControl.playerID = multiplayer.get_peers()[0]
		$MeepleControl.playerID = multiplayer.get_peers()[0]
		for e in enemies:
			e.playerID = multiplayer.get_peers()[1]
	else:
		$BuildingControl.playerID = multiplayer.get_unique_id()
		$MeepleControl.playerID = multiplayer.get_unique_id()
		var opID = 0
		if multiplayer.get_peers()[0] == 1:
			opID = multiplayer.get_peers()[1]
		else:
			opID = multiplayer.get_peers()[0]
		for e in enemies:
			e.playerID = opID
			
	
	buildingControl.teammates.append(meepleControl)
	meepleControl.teammates.append(buildingControl)

	meepleControl.grid = $Grid
	buildingControl.grid = $Grid
	
	add_child(buildingControl)
	add_child(meepleControl)
	
	print(meepleControl.playerID)
	print(buildingControl.playerID)
	print($MeepleControl.playerID)
	print($BuildingControl.playerID)
 

#func _process(_delta): #Runs every tick
	#if !setShit:
		#$MeepleControl.playerID = playerID
		#$BuildingControl.playerID = playerID
		
		#if playerID == multiplayer.get_unique_id():
			
			#$BuildingControl/buildingHud.visible = true
			#GameManager.Players[playerID].meepleInfo = $MeepleControl.unorderedMeeples
			
			#GameManager.ownControllersSet = true
			
		#if multiplayer.is_server():
			#GameManager.ownControllersSet = true
		#setShit = true
	
