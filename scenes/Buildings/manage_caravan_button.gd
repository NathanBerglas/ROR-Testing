extends Control
@onready var button = $"."

var id = 0
var routeNumber = 0
var parentObject = null
func _ready() -> void:
	button.button_down.connect(_on_button_pressed)
	button.button_up.connect(_on_button_released)
	

func _on_button_pressed():
	print("Doing stuff")
	
func _on_button_released():
	parentObject.manageCaravan(id)

func set_id(id):
	self.id = id
	
func set_text(text):
	self.text = text
