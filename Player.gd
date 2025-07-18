extends Node2D

var playerID = 0
@onready var c = [$MeepleControl, $BuildingControl]  #What nodes the player uses
var setShit = false

func _ready() -> void:

	$MeepleControl.teammates.push_back($BuildingControl)
	$BuildingControl.teammates.push_back($MeepleControl)

	
func _process(_delta): #Runs every tick
	if !setShit:
		$MeepleControl.playerID = playerID
		$BuildingControl.playerID = playerID
		if playerID == multiplayer.get_unique_id() or name.to_int() == multiplayer.get_unique_id():
			$BuildingControl/buildingHud.visible = true
		setShit = true
