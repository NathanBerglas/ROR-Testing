extends Building

@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

@onready var manageCaravanMenu = $manageCaravans
@onready var newCaravanButton = $manageCaravans/newCaravanButton

@onready var managingCaravanMenu = $managingCarvanMenu
@onready var finishManagingButton = $managingCarvanMenu/finishManagingButton
@onready var removeRouteButton = $managingCarvanMenu/removeRouteButton

@export var manageCaravanButton: PackedScene

var manageCaravanButtonIDTracker = 1

var managedCaravans = []
var managedCaravanButtons = []

var routeManaging = 0

func _ready():
	newCaravanButton.button_down.connect(_on_newCaravan_button_pressed)
	newCaravanButton.button_up.connect(_on_newCaravan_button_released)
	
	finishManagingButton.button_down.connect(_on_finishManaging_button_pressed)
	finishManagingButton.button_up.connect(_on_finishManaging_button_released)
	
	removeRouteButton.button_down.connect(_on_removeRoute_button_pressed)
	removeRouteButton.button_up.connect(_on_removeRoute_button_released)

	manageCaravanMenu.visible = false
	managingCaravanMenu.visible = false

func _process(_delta):
	if Input.is_action_just_pressed("right_click_menu"):
		manageCaravanMenu.visible = false
		managingCaravanMenu.visible = false
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
	
	instance.parentObject = self
	instance.text = str(instance.id) + " - Manage Caravan " + str(instance.id)
	managedCaravanButtons.push_back(instance)
	
	manageCaravanMenu.visible = false
	
	manageCaravan(instance.id)

func _on_finishManaging_button_pressed():
	print("Hi")
	
func _on_finishManaging_button_released():
	if managingCaravanMenu.visible == false:
		return
	routeManaging = 0
	managingCaravanMenu.visible = false


func _on_removeRoute_button_pressed():
	print("Hi")
	
func _on_removeRoute_button_released():
	if managingCaravanMenu.visible == false:
		return
	removeRoute(routeManaging)
	managingCaravanMenu.visible = false
	

func removeRoute(idToRemove):
	
	var i = 0
	while i < managedCaravanButtons.size():
		if managedCaravanButtons[i].id == idToRemove:
			managedCaravanButtons.pop_at(i).queue_free()
		i += 1

	for r in managedCaravanButtons:
		if r.id > idToRemove:
			r.id -= 1 #This feels wierd, maybe dont do this
		
	
func manageCaravan(id):
	manageCaravanMenu.visible = false
	routeManaging = id
	managingCaravanMenu.visible = true
	var tempVectorYay = self.get_global_position()
	
	tempVectorYay.x -= 50 #Temporary, fix later
	tempVectorYay.y -= 20
	managingCaravanMenu.set_global_position(tempVectorYay)

func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
