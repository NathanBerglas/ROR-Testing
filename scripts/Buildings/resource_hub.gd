extends Building

@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

@onready var manageCaravanMenu = $manageCaravans
@onready var newCaravanButton = $manageCaravans/newCaravanButton

@onready var managingCaravanMenu = $managingCarvanMenu
@onready var finishManagingButton = $managingCarvanMenu/finishManagingButton
@onready var removeRouteButton = $managingCarvanMenu/removeRouteButton

@export var manageCaravanButton: PackedScene
@export var caravanTarget: PackedScene
@export var caravan: PackedScene

const CARAVAN_WAIT_TIMER = 2


var manageCaravanButtonIDTracker = 1
var routeNumTracker = 1

var managedCaravans = []
var managedRoutes = []
var tempRoute = []
var tempTargets = []

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

func _process(delta):
	if Input.is_action_just_pressed("right_click_menu"):
		if managingCaravanMenu.visible == true:
			_on_finishManaging_button_released()
		manageCaravanMenu.visible = false
		managingCaravanMenu.visible = false
	if Input.is_action_just_pressed("select"):
		if routeManaging != 0 and controller.grid.coord_to_axial_hex(get_global_mouse_position()) != controller.grid.coord_to_axial_hex(self.get_global_position()):
			if tempRoute.size() < 3:
				tempRoute.append(controller.grid.hex_center(get_global_mouse_position()))
				var instance = caravanTarget.instantiate()
				add_child(instance)
				instance.label.text = str(tempRoute.size())
				instance.set_global_position(controller.grid.hex_center(get_global_mouse_position()))
				tempTargets.append(instance)
	
	for r in managedRoutes:
		if r[0][0] != -1:
			r[0][0] += delta
			print(r[0])
			if r[0][0] > CARAVAN_WAIT_TIMER:
				r[0][0] = -1
				sendCaravan(r, r[0][1])

		
	for c in managedCaravans: #When Caravans return home
		if c.path == null or c.path.size() == 0:
			
			if c.routeRemoved == false:
				for r in managedRoutes:
					
					
					if r[0][1] == c.UNIQUEID:
						r[0][0] = 0

			freeCaravan(c.UNIQUEID)
			

func _on_newCaravan_button_pressed():
	if manageCaravanMenu.visible == false:
		return
	
func _on_newCaravan_button_released():
	if manageCaravanMenu.visible == false:
		return
	
	
	
	var instance = manageCaravanButton.instantiate()	
	# Set instance's data
	instance.set_id(manageCaravanButtonIDTracker)
	instance.routeNumber = routeNumTracker
	routeNumTracker += 1
	manageCaravanButtonIDTracker += 1
	#instance.target = group_targets[0]
	# Create instance
	
	manageCaravanMenu.add_child(instance)
	
	instance.parentObject = self
	instance.text = str(instance.routeNumber + 1) + " - Manage Caravan " + str(instance.routeNumber)
	managedCaravanButtons.push_back(instance)
	
	manageCaravanMenu.visible = false
	
	manageCaravan(instance.id)

func _on_finishManaging_button_pressed():
	var what = "huh"
	
func _on_finishManaging_button_released():
	if managingCaravanMenu.visible == false:
		return
	
	managingCaravanMenu.visible = false
	var tempArray = []
	if routeManaging > managedRoutes.size():
		tempArray.append([0, routeManaging])
	else:
		for r in managedRoutes:
			if r[0][1] == routeManaging:
				tempArray.append([r[0][0], routeManaging])
				
	for v in tempRoute:
		tempArray.append(v)
	if routeManaging > managedRoutes.size():
		managedRoutes.append(tempArray)
	else:
		for r in managedRoutes:
			if r.id == routeManaging:
				r = tempArray 
	tempRoute = []
	var i = 0
	while i < tempTargets.size():
		tempTargets.pop_at(i).queue_free()
	
	routeManaging = 0


func _on_removeRoute_button_pressed():
	var what = "huh"
	
func _on_removeRoute_button_released():
	if managingCaravanMenu.visible == false:
		return
	removeRoute(routeManaging)
	for c in managedCaravans:
		if c.UNIQUEID == routeManaging:
			c.routeRemoved = true
	routeManaging = 0
	managingCaravanMenu.visible = false
	

func removeRoute(idToRemove):
	var i = 0
	var removingRoute = 0
	while i < managedCaravanButtons.size():
		if managedCaravanButtons[i].id == idToRemove:
			removingRoute = managedCaravanButtons[i].routeNumber
			managedCaravanButtons.pop_at(i).queue_free()
		i += 1
	i = 0
	while i < managedRoutes.size():
		if managedRoutes[i][0][1] == idToRemove:
			managedRoutes.pop_at(i)
			break
		i += 1
		
	var max = 1
	for r in managedCaravanButtons:
		if r.routeNumber > removingRoute:
			if r.routeNumber > max:
				max = r.routeNumber
			r.routeNumber -= 1
			r.text = str(r.routeNumber + 1) + " - Manage Caravan " + str(r.routeNumber)
	routeNumTracker = max
	var t = 0
	while t < tempTargets.size():
		tempTargets.pop_at(i).queue_free()
	
func manageCaravan(id):
	manageCaravanMenu.visible = false
	routeManaging = id
	managingCaravanMenu.visible = true
	var tempVectorYay = self.get_global_position()
	
	tempVectorYay.x -= 50 #Temporary, fix later
	tempVectorYay.y -= 20
	managingCaravanMenu.set_global_position(tempVectorYay)


	
func sendCaravan(route, routeID):
	var instance = caravan.instantiate()
	var tempPath = []
	
	var i = 1
	while i < route.size():
		tempPath.append(route[i])
		i += 1
	
	tempPath.append(self.get_global_position())
	
	instance.path = tempPath
	instance.UNIQUEID = routeID
	add_child(instance)
	managedCaravans.append(instance)

func freeCaravan(caravanID):
	var i = 0
	while i < managedCaravans.size():
		if managedCaravans[i].UNIQUEID == caravanID:
			managedCaravans.pop_at(i).queue_free()
		i += 1
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
