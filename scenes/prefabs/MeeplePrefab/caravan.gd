extends meeple



var woodCarrying = 0
var foodCarrying = 0
var stoneCarrying = 0

var pathwayNodes = []
var tempPathwayNodes = []

func _ready():
	self.rb = $RigidBody2D
	self.sprite = $RigidBody2D/Sprite2D
	self.label = $RigidBody2D/Label
	self.type = "Caravan"


func _process(delta): #runs on each meeple every tick
	label.text = str(HP)
	
	
	
	if (path != null and shouldBeMoving): #if a meeple has somewhere to go, goes to it
		_go_to_target(delta)
	
	#if dest != null and closeEnough(): #meeple reaches destination
		#dest = null
	
func get_id():
	return self.UNIQUEID
func set_id(id):
	self.UNIQUEID = id
