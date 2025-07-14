extends Node2D

var playerID = 0
func _ready() -> void:
	$MeepleControl.teammates.push_back($BuildingControl)
	$BuildingControl.teammates.push_back($MeepleControl)
	#bandaid solution - FIX LATER - host name is set to 0
	if name.to_int() == 0:
		name = "1"
		print("Hey *wink*")
	
	$MeepleControl.playerID = playerID
	$BuildingControl.playerID = playerID
	
	
	if playerID == multiplayer.get_unique_id() or name.to_int() == multiplayer.get_unique_id():
		print("HI!")
		$BuildingControl/buildingHud.visible = true
	#$BuildingControl/buildingHud.visible = multiplayer.get_unique_id() == get_multiplayer_authority()
	
	#$MeepleControl/MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	#$BuildingControl/MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	
	#$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	
