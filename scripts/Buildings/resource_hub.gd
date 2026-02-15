extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR
@onready var manageCaravanMenu = $manageCaravans
@onready var newCaravanButton = $manageCaravans/newCaravanButton

@export var manageCaravanButton: PackedScene

var manageCaravanButtonIDTracker = 2
var managedCaravans = []
var managedCaravanButtons = []




func _ready():
	newCaravanButton.button_down.connect(_on_newCaravan_button_pressed)
	newCaravanButton.button_up.connect(_on_newCaravan_button_released)
	

	manageCaravanMenu.visible = false


func _on_newCaravan_button_pressed():
	if manageCaravanMenu.visible == false:
		return
	
func _on_newCaravan_button_released():
	if manageCaravanMenu.visible == false:
		return
	
	
	
	var instance = manageCaravanButton.instantiate()	
	# Set instance's data
	instance.set_id(manageCaravanButtonIDTracker)
	manageCaravanButtonIDTracker += 1
	#instance.target = group_targets[0]
	# Create instance
	
	manageCaravanMenu.add_child(instance)
	
	instance.text = str(instance.id) + " - Manage Caravan " + str(instance.id)
	managedCaravanButtons.push_back(instance)
	
	manageCaravanMenu.visible = false

func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
