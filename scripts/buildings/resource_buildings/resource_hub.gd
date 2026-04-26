extends Building


const FLAG_VERBOSE = false

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
const MAX_CARAVAN_STOPS = 3
const CARAVAN_TICKS_PER_SECOND = 60
var time_since_last_caravan_tick = 0

var manageCaravanButtonIDTracker = 1
var routeNumTracker = 1

var managedCaravans = []
var managedRoutes = []
var tempRoute = []
var tempTargets = []

var managedCaravanButtons = []

var routeManaging = 0


var size = 1
const HEX_SHAPE := [ #Vector2i(1, 0) for meeple dock
	Vector2i(0, 0),
	Vector2i(-1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]
var meepleDocPos = null
	
func _ready():
	newCaravanButton.button_down.connect(_on_newCaravan_button_pressed)
	newCaravanButton.button_up.connect(_on_newCaravan_button_released)
	
	finishManagingButton.button_down.connect(_on_finishManaging_button_pressed)
	finishManagingButton.button_up.connect(_on_finishManaging_button_released)
	
	removeRouteButton.button_down.connect(_on_removeRoute_button_pressed)
	removeRouteButton.button_up.connect(_on_removeRoute_button_released)

	manageCaravanMenu.visible = false
	managingCaravanMenu.visible = false
	set_size(size)

func _process(delta):
	time_since_last_caravan_tick += delta
	#if playerID == multiplayer.get_unique_id():
	if time_since_last_caravan_tick > (1.0 / CARAVAN_TICKS_PER_SECOND):
		caravan_process(time_since_last_caravan_tick)
		time_since_last_caravan_tick = 0
	
	if playerID == multiplayer.get_unique_id():
		if Input.is_action_just_pressed("right_click_menu"):
			if managingCaravanMenu.visible == true:
				_on_finishManaging_button_released()
			manageCaravanMenu.visible = false
			managingCaravanMenu.visible = false
		if Input.is_action_just_pressed("select"): #Managing a route -> Make a new target
			if routeManaging != 0 and controller.grid.coord_to_axial_hex(get_global_mouse_position()) != controller.grid.coord_to_axial_hex(self.get_global_position()):
				if tempRoute.size() < 3 and controller.grid.hex_center(get_global_mouse_position()) not in tempRoute:
					
					tempRoute.append(controller.grid.hex_center(get_global_mouse_position()))
					var instance = caravanTarget.instantiate()
					add_child(instance)
					instance.label.text = str(tempRoute.size())
					instance.set_global_position(controller.grid.hex_center(get_global_mouse_position()))
					tempTargets.append(instance)
				
	
	for r in managedRoutes: #Timing to send caravans out
		if r[0][0] != -1:
			
			r[0][0] += delta
			#print(r[0])
			if r[0][0] > CARAVAN_WAIT_TIMER:
				r[0][0] = -1
				sendCaravan(r, r[0][1])

		
	for c in managedCaravans: #When Caravans return home
		if c.returned:
			if c.routeRemoved == false:
				for r in managedRoutes:	
					if r[0][1] == c.UNIQUEID:
						r[0][0] = 0
			controller.food += c.foodCarrying
			controller.wood += c.woodCarrying
			controller.stone += c.stoneCarrying
			print("Food delivered: " + str(c.foodCarrying))
			freeCaravan(c.UNIQUEID)
			
func _physics_process(delta: float) -> void:
	for c in managedCaravans:
		if !c.shouldBeMoving:
			continue
		var next_hex: Vector2 = controller.grid.axial_hex_to_coord(c.path[1])
		var dir_to_next_hex = (next_hex - c.global_position) / (next_hex - c.global_position).length()
		var speed = 2 * c.speed / (controller.grid.grid[c.path[0].x][c.path[0].y].traversal_difficulty + controller.grid.grid[c.path[1].x][c.path[1].y].traversal_difficulty)
		if (next_hex - c.global_position).length() >= c.speed * delta: # Not yet arrived

			c.global_position += dir_to_next_hex * speed * delta
		else: # Just entered the hex
			c.pause_a_tick = true
			c.global_position = next_hex
			var next_hex_tile = controller.grid.axial_probe(c.path[1])
			controller.grid.update_grid(c.path[1], 3, [c])
			c.path.pop_front()
			#if FLAG_VERBOSE: print("Meeple ", c.UNIQUEID, " has stopped moving at position ", c.global_position, " in hex: ", next_hex)
			c.shouldBeMoving = false


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
	return
	
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
	
	var tempTempArray = []
	for v in tempRoute:
		tempTempArray.append(v)
	tempArray.append(tempTempArray)
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
	return
	
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
		
	var routemax = 1
	for r in managedCaravanButtons:
		if r.routeNumber > removingRoute:
			if r.routeNumber > routemax:
				routemax = r.routeNumber
			r.routeNumber -= 1
			r.text = str(r.routeNumber + 1) + " - Manage Caravan " + str(r.routeNumber)
	routeNumTracker = routemax
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
	
	var meepleDocPos = controller.grid.coord_to_axial_hex(self.get_global_position()) + Vector2i(1,0)
	
	
	
	instance.queued_path = controller.grid.find_path(meepleDocPos, controller.grid.coord_to_axial_hex(route[1][0]), false, false) #To first locations
	instance.UNIQUEID = routeID
	controller.grid.update_grid(meepleDocPos, 3, [instance])
	add_child(instance)
	instance.set_global_position(controller.grid.axial_hex_to_coord(meepleDocPos))
	instance.route = route
	instance.path = [meepleDocPos]
	instance.totalStops = route[1].size()
	instance.stop = 0
	managedCaravans.append(instance)
	
func freeCaravan(caravanID): 
	var i = 0
	while i < managedCaravans.size():
		if managedCaravans[i].UNIQUEID == caravanID:
			controller.grid.update_grid(managedCaravans[i].path[0], 0, [])
			managedCaravans.pop_at(i).queue_free()
			return
		i += 1

func caravan_process(delta):
	for c in managedCaravans:
		if c.atStop:
			
			c.stopTimer += delta
			
			for h in controller.grid.HEX_DIRS:
				if controller.grid.axial_probe(c.path[0] + h).classification == 2:
					
					var objectInside = controller.grid.axial_probe(c.path[0] + h).objectsInside[0]
					
					if objectInside.type == "stoneMine":
						objectInside.saved_stone -= 1
						c.stoneCarrying += 1
					if objectInside.type == "farm":
						objectInside.saved_food -= 1
						c.foodCarrying += 1
					if objectInside.type == "lumberjack":
						objectInside.saved_wood -= 1
						c.woodCarrying += 1
			if c.stopTimer >= c.MAX_STOP_TIMER:
				
				c.atStop = false
				c.stopTimer = 0
				c.stop += 1
				if c.stop < c.totalStops:
					c.queued_path = controller.grid.find_path(c.path[0], controller.grid.coord_to_axial_hex(c.route[1][c.stop]), false, false) 
				else:
					c.queued_path = controller.grid.find_path(c.path[0], meepleDocPos, false, false) 
		if c.pause_a_tick:
			c.pause_a_tick = false
			
			continue
		if (c.shouldBeMoving || c.waiting):
			
			continue
		if not c.queued_path.is_empty():
			
			
			c.path = controller.grid.find_path(c.path[0], c.queued_path[c.queued_path.size() - 1], false, false)
			#c.path = c.queued_path#.slice(1) # Remove first hex in queued path
			c.queued_path = []
		if (c.path.size() > 1):
			var ingress_result = controller.grid.hex_ingress(c.path[1], c)
			if (ingress_result == "REDIRECTED"): # Redirected
				c.redirected_from.append(c.path[1])
				c.queued_path = controller.grid.redirected_find_path(c.path, false, false, c.redirected_from)
			else:
				c.redirected_from = []
				if (ingress_result == "APPROVED"):
					controller.grid.hex_egress(c.path[0])
					c.shouldBeMoving = true
					continue
				elif (ingress_result == "PENDING"):
					c.redirected_from = []
					c.waiting = true
					if FLAG_VERBOSE: print("Meeple ", c.UNIQUEID, " set to waiting due to pending ingress.")
					continue
		if c.path.size() == 1 and c.queued_path.size() == 0:
			
			if controller.grid.coord_to_axial_hex(c.get_global_position()) == meepleDocPos:
				c.returned = true
			else:
				c.atStop = true



func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
