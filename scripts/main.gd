extends Node



func _ready():
	$MeepleControl.teammates.push_back($BuildingControl)
	$BuildingControl.teammates.push_back($MeepleControl)

func _process(_delta): #runs every
	var x = 0
	#We vibin
