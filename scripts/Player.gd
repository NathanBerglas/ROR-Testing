extends Node2D

var playerID = 0
@onready var c = [$MeepleControl, $BuildingControl]  #What nodes the player uses
var setShit = false
var time = 0
func _ready() -> void:

	$MeepleControl.teammates.push_back($BuildingControl)
	$BuildingControl.teammates.push_back($MeepleControl)
	$BuildingControl/buildingHud.visible = true
	
	
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
	
