extends meeple

@export var enemy_texture: Texture2D

var building = null
var building_time = null

var atStop = false
var stopTimer = 0

var pathwayNodes = []
var tempPathwayNodes = []

var returned = false


func _ready():
	self.rb = $CharecterBody2D
	self.sprite = $Sprite2D
	self.label = $Label
	self.type = "Builder"
	if player_id != multiplayer.get_unique_id():
		$Sprite2D.texture = enemy_texture


func _process(delta):  #runs on each meeple every tick
	label.text = str(HP)


func get_id():
	return self.UNIQUEID


func set_id(id):
	self.UNIQUEID = id
