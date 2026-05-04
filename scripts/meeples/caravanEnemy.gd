extends meeple

const MAX_STOP_TIMER = 2

var woodCarrying = 0
var foodCarrying = 0
var stoneCarrying = 0

var atStop = false
var stopTimer = 0
var stop = null
var totalStops = null
var routeRemoved = false

var pathwayNodes = []
var tempPathwayNodes = []

var route = null
var returned = false


func _ready():
	self.rb = $CharecterBody2D
	self.sprite = $Sprite2D
	self.label = $Label
	self.type = "Caravan"


func _process(delta):  #runs on each meeple every tick
	label.text = str(HP)

	#if (path != null and shouldBeMoving): #if a meeple has somewhere to go, goes to it
	#_go_to_target(delta)

	#if dest != null and closeEnough(): #meeple reaches destination
	#dest = null


func get_id():
	return self.UNIQUEID


func set_id(id):
	self.UNIQUEID = id
