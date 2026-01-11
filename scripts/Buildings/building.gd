extends Node2D
class_name Building 

@onready var building_type := str(null)  # must be overridden

#A list of the costs of each building
var buildingCosts = [["Barracks", 1000], ["Farm", 500]] 

var fake = false #Check if this is dragging or NAH
var playerID = 0

#Dont ask Jacob WTF this code is. ChatGPT wrote is
