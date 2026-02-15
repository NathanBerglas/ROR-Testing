extends Node2D
@onready var hud = $buildingHud

@onready var farmButton = $buildingHud/FarmButton
@onready var stoneMineButton = $buildingHud/StoneMineButton
@onready var lumberJackButton = $buildingHud/LumberJackButton
@onready var resourceHubButton = $buildingHud/ResourceHubButton
@onready var barracksButton = $buildingHud/BarracksButton

@onready var selection_box = $ColorRect

@onready var RCLICKMENU = $RclickMenuResourceHub
@onready var manageCaravansButton = $RclickMenuResourceHub/manageCaravansButton


@export var farm_prefab: PackedScene
@export var lumberJack_prefab: PackedScene
@export var stoneMine_prefab: PackedScene
@export var resourceHub_prefab: PackedScene
@export var barracks_prefab: PackedScene



#Players Money
var food = 10000
var wood = 10000
var stone = 10000

#Checking what type of building the player is dragging
var buildingDraggin = null

#A list of the buildings owned
#Format is: ["Building Name", Vector(Building Pos), Building itself]
var buildings = [] 

var teammates = [] #list of teammates
var grid # the grid controller
var playerID = 0
var buildingIDTracker = 0
var caravanIDTracker = 1

func _ready(): #Runs on start, connects buttons
	farmButton.button_down.connect(_on_farm_button_pressed)
	farmButton.button_up.connect(_on_farm_button_released)
	farmButton.custom_minimum_size = Vector2(121.6,120)
	
	lumberJackButton.button_down.connect(_on_lumberJack_button_pressed)
	lumberJackButton.button_up.connect(_on_lumberJack_button_released)
	lumberJackButton.custom_minimum_size = Vector2(121.6,120)
	
	stoneMineButton.button_down.connect(_on_stoneMine_button_pressed)
	stoneMineButton.button_up.connect(_on_stoneMine_button_released)
	stoneMineButton.custom_minimum_size = Vector2(121.6,120)
	
	resourceHubButton.button_down.connect(_on_resourceHub_button_pressed)
	resourceHubButton.button_up.connect(_on_resourceHub_button_released)
	resourceHubButton.custom_minimum_size = Vector2(121.6,120)
	
	barracksButton.button_down.connect(_on_barracks_button_pressed)
	barracksButton.button_up.connect(_on_barracks_button_released)
	barracksButton.custom_minimum_size = Vector2(121.6,120)
	
	manageCaravansButton.button_down.connect(_on_manageCaravans_button_pressed)
	manageCaravansButton.button_up.connect(_on_manageCaravans_button_released)
	
	RCLICKMENU.visible = false

	#print(playerID)
	


func _on_manageCaravans_button_pressed():
	if RCLICKMENU.visible == false:
		return
	
	
func _on_manageCaravans_button_released():
	if RCLICKMENU.visible == false:
		return
	var resourceHubAtLocation = grid.probe(RCLICKMENU.get_global_position()).objectsInside[0]
	resourceHubAtLocation.manageCaravanMenu.visible = true
	resourceHubAtLocation.manageCaravanMenu.set_global_position(RCLICKMENU.get_global_position())
	
	
	RCLICKMENU.visible = false
	
#Start dragging the farm if has enough money
func _on_farm_button_pressed():
	if food < 500 or stone < 500 or wood < 500:
		print("Ya Broke")
		return
	
	
	buildingDraggin = "Farm"
	#money -= 500
	#Adding the farm to be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = farm_prefab.instantiate() #New FAKE money farm
	instance.fake = true
	instance.type = "Farm"
	#instance.$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	#var toAdd = ["Farm", get_global_mouse_position(), instance]
	instance.BUILDING_UNIQUE_ID = buildingIDTracker
	buildingIDTracker += 1
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	

#finishes dragging the farm and places
func _on_farm_button_released():
	
	if buildingDraggin != "Farm" or wood < 500 or stone < 500 or food < 500:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !is_placeable(buildings[buildings.size() - 1]):
		buildings.pop_back().queue_free()
		return
	buildings[buildings.size() - 1].fake = false
	buildings[buildings.size() - 1].global_position = grid.hex_center(get_global_mouse_position())
	buildings[buildings.size() - 1].pos = grid.coord_to_axial_hex(get_global_mouse_position())
	
	grid.update_grid(grid.coord_to_axial_hex(get_global_mouse_position()), 2, [buildings[buildings.size() - 1]])
	print("Added Farm")
	food -= 500
	wood -= 500
	stone -= 500
	

#starts draggin the lumberJack
func _on_lumberJack_button_pressed():
	if food < 500 or stone < 500 or wood < 500:
		print("Ya Broke")
		return
	
	
	buildingDraggin = "LumberJack"
	#money -= 500
	#Adding the farm to be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = lumberJack_prefab.instantiate() #New FAKE money farm
	instance.fake = true
	instance.type = "LumberJack"
	#instance.$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	#var toAdd = ["Farm", get_global_mouse_position(), instance]
	instance.BUILDING_UNIQUE_ID = buildingIDTracker
	buildingIDTracker += 1
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	

#finishes dragging the lumberJack and places
func _on_lumberJack_button_released():
	
	if buildingDraggin != "LumberJack" or wood < 500 or stone < 500 or food < 500:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !is_placeable(buildings[buildings.size() - 1]):
		buildings.pop_back().queue_free()
		return
	buildings[buildings.size() - 1].fake = false
	buildings[buildings.size() - 1].global_position = grid.hex_center(get_global_mouse_position())
	buildings[buildings.size() - 1].pos = grid.coord_to_axial_hex(get_global_mouse_position())
	
	grid.update_grid(grid.coord_to_axial_hex(get_global_mouse_position()), 2, [buildings[buildings.size() - 1]])
	print("Added LumberJack")
	food -= 500
	wood -= 500
	stone -= 500
	
#Starts draggin the Stone mine
func _on_stoneMine_button_pressed():
	if food < 500 or stone < 500 or wood < 500:
		print("Ya Broke")
		return
	
	
	buildingDraggin = "StoneMine"
	#money -= 500
	#Adding the farm to be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = stoneMine_prefab.instantiate() #New FAKE money farm
	instance.fake = true
	instance.type = "StoneMine"
	#instance.$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	#var toAdd = ["Farm", get_global_mouse_position(), instance]
	instance.BUILDING_UNIQUE_ID = buildingIDTracker
	buildingIDTracker += 1
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	

#finishes dragging the Stone Mine and places
func _on_stoneMine_button_released():
	
	if buildingDraggin != "StoneMine" or wood < 500 or stone < 500 or food < 500:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !is_placeable(buildings[buildings.size() - 1]):
		buildings.pop_back().queue_free()
		return
	buildings[buildings.size() - 1].fake = false
	buildings[buildings.size() - 1].global_position = grid.hex_center(get_global_mouse_position())
	buildings[buildings.size() - 1].pos = grid.coord_to_axial_hex(get_global_mouse_position())
	
	grid.update_grid(grid.coord_to_axial_hex(get_global_mouse_position()), 2, [buildings[buildings.size() - 1]])
	print("Added StoneMine")
	food -= 500
	wood -= 500
	stone -= 500


#Start dragging the resource hub if has enough money
func _on_resourceHub_button_pressed():
	if food < 5000 or stone < 5000 or wood < 5000:
		print("Ya Broke")
		return
	
	
	buildingDraggin = "ResourceHub"
	#money -= 500
	#Adding the farm to be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = resourceHub_prefab.instantiate() #New FAKE money farm
	instance.fake = true
	instance.type = "ResourceHub"
	#instance.$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	#var toAdd = ["Farm", get_global_mouse_position(), instance]
	instance.BUILDING_UNIQUE_ID = buildingIDTracker
	buildingIDTracker += 1
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	

#finishes dragging the resource hub and places
func _on_resourceHub_button_released():
	
	if buildingDraggin != "ResourceHub" or wood < 5000 or stone < 5000 or food < 5000:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !is_placeable(buildings[buildings.size() - 1]):
		buildings.pop_back().queue_free()
		return
	buildings[buildings.size() - 1].fake = false
	buildings[buildings.size() - 1].global_position = grid.hex_center(get_global_mouse_position())
	buildings[buildings.size() - 1].pos = grid.coord_to_axial_hex(get_global_mouse_position())
	
	grid.update_grid(grid.coord_to_axial_hex(get_global_mouse_position()), 2, [buildings[buildings.size() - 1]])
	print("Added Resource Hub")
	food -= 5000
	wood -= 5000
	stone -= 5000
	
func _on_barracks_button_pressed():
	if food < 1000 or wood < 1000 or stone < 1000:
		print("Ya Broke")
		return
	buildingDraggin = "Barracks"
	
	#Adding the barracksto be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = barracks_prefab.instantiate() #New FAKE barracks
	instance.fake = true
	#var toAdd = ["Barracks", Vector2(0,0), instance]
	instance.type = "Barracks"
	instance.global_position = get_global_mouse_position()
	instance.BUILDING_UNIQUE_ID = buildingIDTracker
	buildingIDTracker += 1
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	
func _on_barracks_button_released():
	
	if buildingDraggin != "Barracks" or food < 1000 or wood < 1000 or stone < 1000:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !is_placeable(buildings[buildings.size() - 1]):
		buildings.pop_back().queue_free()
		return
	buildings[buildings.size() - 1].fake = false
	buildings[buildings.size() - 1].global_position = grid.hex_center(get_global_mouse_position())
	buildings[buildings.size() - 1].pos = grid.coord_to_axial_hex(get_global_mouse_position())
	
	
	grid.update_grid(grid.coord_to_axial_hex(get_global_mouse_position()), 2, [buildings[buildings.size() - 1]])
	var tempVector = grid.coord_to_axial_hex(get_global_mouse_position())
	tempVector.x += 1
	grid.update_grid(tempVector, 1, ["Training Ground"])
	
	food -= 1000
	wood -= 1000
	stone -= 1000
	
	
func _process(delta): #runs every tick
	cleanBuildings()
	#Opens up the right click menu
	if Input.is_action_just_pressed("right_click_menu"):
		if grid.probe(get_global_mouse_position()).objectsInside.size() > 0 and grid.probe(get_global_mouse_position()).objectsInside[0].type == "ResourceHub":
			RCLICKMENU.set_global_position(get_global_mouse_position())
			RCLICKMENU.visible = true
		else:
			RCLICKMENU.visible = false
		
	for b in buildings:
		b.updateHPBar()
	if buildingDraggin != null: #Code actually dragging the building around
		buildings[buildings.size() - 1].global_position = get_global_mouse_position()
		if !is_placeable(buildings[buildings.size() - 1]):
			buildings[buildings.size() - 1].shapey.modulate = Color(250, 0, 4) #RED
		else:
			buildings[buildings.size() - 1].shapey.modulate = Color(1, 1, 1)  # Reset to white

	for m in buildings: #Doing tick stuff for each building
		if m.type == "Farm" and !m.fake:
			m.generateFood(self, delta)
		elif m.type == "Barracks" and !m.fake:
			m.spawn(self.teammates[0],delta,m.pos, grid)
		elif m.type == "LumberJack" and !m.fake:
			m.generateWood(self, delta)
		elif m.type == "StoneMine" and !m.fake:
			m.generateStone(self, delta)
	sendCaravans()
	
	hud.updateFood(food) 
	hud.updateWood(wood) 
	hud.updateStone(stone) 
func sendCaravans():
	return
	#for b in buildings:
	#	if b.type == "Farm":
			#if b.collectedFood >= 1000:
func addFood(foodChange): #Changing money
	food += foodChange
	hud.updateFood(food)
func addWood(woodChange): #Changing money
	wood += woodChange
	hud.updateWood(wood)
func addStone(stoneChange): #Changing money
	stone += stoneChange
	hud.updateStone(stone)
	
func takeDamage(b, x):
	b.hp -= x
	
func is_placeable(building) -> bool: #Only for if a body is FAKE
	
	
	if grid.probe(get_global_mouse_position()).classification != 0:
		
		return false
	else:
		
		if building.type == "Farm":
			if grid.probe(get_global_mouse_position()).type != "ARABLE":
				return false
			else:
				return true
		elif building.type == "StoneMine":
			if grid.probe(get_global_mouse_position()).type != "STONE":
				return false
			else:
				return true
		elif building.type == "LumberJack":
			if grid.probe(get_global_mouse_position()).type != "FOREST":
				return false
			else:
				return true
		else: #is a barracks
			return true





func cleanBuildings():
	
	for b in buildings:
		if b.hp <= 0:
			freeBuilding(b.BUILDING_UNIQUE_ID)
			



func freeBuilding(ID):
	
	for i in range(buildings.size()):
		if buildings[i].BUILDING_UNIQUE_ID == ID:
			grid.update_grid(buildings[i].pos, 0, [])
			buildings.pop_at(i).queue_free()
			return




""" Old Code -> Updated to right above
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	query.shape = $RigidBody2D/CollisionShape2D.shape
	query.transform = $RigidBody2D/CollisionShape2D.global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [$RigidBody2D.get_rid()]
	var result = space_state.intersect_shape(query)
	return result.is_empty()  # True = no collision, so placeable
"""
