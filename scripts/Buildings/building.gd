extends Node2D
class_name Building 
@onready var hpBar = $ProgressBar
@onready var building_type := str(null)  # must be overridden

#A list of the costs of each building
var buildingCosts = [["Barracks", 1000], ["Farm", 500]] 

var fake = false #Check if this is dragging or NAH
var playerID = 0
var hp = 100
var type = ""
var pos = null
var BUILDING_UNIQUE_ID = 0
var controller = null
