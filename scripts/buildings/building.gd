extends Node2D
class_name Building 
@onready var hpBar = $ProgressBar
@onready var building_type := str(null)  # must be overridden



var fake = false #Check if this is dragging or NAH
var player_id = 0
var hp = 100
var type = ""
var pos = null
var BUILDING_UNIQUE_ID = 0
var controller = null
var superType = "Building"

func set_size(size):
	self.scale = Vector2i(1, 1) * size
