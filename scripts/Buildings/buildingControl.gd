extends Node2D
@onready var hud = $buildingHud

#Ensuring all of our prebabs and their buttons are loaded in
@onready var farmButton = $resourceBuildingHud/ScrollContainer/VBoxContainer/FarmButton
@onready var farmLabel = $resourceBuildingHud/FarmButtonLabel
@export var farm_prefab: PackedScene


@onready var stoneMineButton = $resourceBuildingHud/ScrollContainer/VBoxContainer/StoneMineButton
@onready var stoneMineLabel = $resourceBuildingHud/StoneMineButtonLabel2
@export var stoneMine_prefab: PackedScene


@onready var lumberJackButton = $resourceBuildingHud/ScrollContainer/VBoxContainer/LumberJackButton
@onready var lumberJackLabel = $resourceBuildingHud/LumberJackButtonLabel
@export var lumberJack_prefab: PackedScene


@onready var resourceHubButton = $resourceBuildingHud/ScrollContainer/VBoxContainer/ResourceHubButton
@onready var resourceHubLabel = $resourceBuildingHud/ResourceHubButtonLabel
@export var resourceHub_prefab: PackedScene


@onready var barracksButton = $combatBuildingHud/ScrollContainer/VBoxContainer/BarracksButton
@onready var barracksLabel = $combatBuildingHud/BarracksButtonLabel
@export var barracks_prefab: PackedScene


@onready var wallCornerButton = $combatBuildingHud/ScrollContainer/VBoxContainer/wallCornerButton
@onready var wallCornerLabel = $combatBuildingHud/wallCornerButtonLabel
@export var wallCorner_prefab: PackedScene
@export var wallSegment_prefab: PackedScene

#Combat building menu
@onready var combatBuildingMenu = $combatBuildingHud/ScrollContainer
@onready var closeCombatBuilding = $combatBuildingHud/ScrollContainer/VBoxContainer/closeCombatMenu
@onready var combatBuildingMenuButton = $buildingHud/combatBuildingButton
@onready var combatBuildingLabel = $buildingHud/combatBuildingsLabel

#Resource building menu
@onready var resourceBuildingMenu = $resourceBuildingHud/ScrollContainer
@onready var resourceBuildingMenuButton = $buildingHud/resourceBuildingButton
@onready var closeResourceBuilding = $resourceBuildingHud/ScrollContainer/VBoxContainer/closeResourceMenu
@onready var resourceBuildingLabel = $buildingHud/resourceBuildingLabel

#IDK why this is here
@onready var selection_box = $ColorRect

#Menu for the resource hub
@onready var RCLICK_ResourceHub = $RclickMenuResourceHub
@onready var manageCaravansButton = $RclickMenuResourceHub/manageCaravansButton








#Players Money
var food = 10000
var wood = 10000
var stone = 10000

#All the buttons for resources
var resourceButtons = []
var combatButtons = []
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

	
	lumberJackButton.button_down.connect(_on_lumberJack_button_pressed)
	lumberJackButton.button_up.connect(_on_lumberJack_button_released)

	
	stoneMineButton.button_down.connect(_on_stoneMine_button_pressed)
	stoneMineButton.button_up.connect(_on_stoneMine_button_released)

	
	resourceHubButton.button_down.connect(_on_resourceHub_button_pressed)
	resourceHubButton.button_up.connect(_on_resourceHub_button_released)

	
	barracksButton.button_down.connect(_on_barracks_button_pressed)
	barracksButton.button_up.connect(_on_barracks_button_released)
	
	
	manageCaravansButton.button_down.connect(_on_manageCaravans_button_pressed)
	manageCaravansButton.button_up.connect(_on_manageCaravans_button_released)
	
	resourceBuildingMenuButton.button_down.connect(_on_resourceBuildingMenu_button_pressed)
	resourceBuildingMenuButton.button_up.connect(_on_resourceBuildingMenu_button_released)
	
	closeResourceBuilding.button_down.connect(_on_closeResourceMenu_button_pressed)
	closeResourceBuilding.button_up.connect(_on_closeResourceMenu_button_released)
	
	combatBuildingMenuButton.button_down.connect(_on_combatBuildingMenu_button_pressed)
	combatBuildingMenuButton.button_up.connect(_on_combatBuildingMenu_button_released)
	
	closeCombatBuilding.button_down.connect(_on_closeCombatMenu_button_pressed)
	closeCombatBuilding.button_up.connect(_on_closeCombatMenu_button_released)
	
	wallCornerButton.button_down.connect(_on_wallCorner_button_pressed)
	wallCornerButton.button_up.connect(_on_wallCorner_button_released)

	farmLabel.visible = false
	stoneMineLabel.visible = false
	lumberJackLabel.visible = false
	resourceHubLabel.visible = false
	resourceBuildingMenu.visible = false
	wallCornerLabel.visible = false
	
	resourceButtons.append([stoneMineButton, stoneMineLabel])
	resourceButtons.append([farmButton, farmLabel])
	resourceButtons.append([lumberJackButton, lumberJackLabel])
	resourceButtons.append([resourceHubButton, resourceHubLabel])
	
	combatButtons.append([barracksButton, barracksLabel])
	combatButtons.append([wallCornerButton, wallCornerLabel])
	RCLICK_ResourceHub.visible = false

	#print(playerID)
	

func _on_wallCorner_button_pressed():
	if food < 50 or stone < 50 or wood < 50:
		print("Ya Broke")
		return
	
	
	beginDragging("WallCorner")

func _on_wallCorner_button_released():
	if buildingDraggin != "WallCorner" or wood < 50 or stone < 50 or food < 50:
		buildingDraggin = null
		return
	if finishDragging("WallCorner") == false:
		return
	var corner = buildings[buildings.size() - 1]
	
	for d in grid.HEX_DIRS:
		var objectsInside = grid.axial_probe(grid.coord_to_axial_hex(corner.get_global_position()) + d).objectsInside
		if objectsInside.size() > 0 and objectsInside[0].type == "WallCorner":
			var direction = corner.get_global_position() - objectsInside[0].get_global_position()
			var length = direction.length()
			var midpoint = corner.get_global_position() + (direction * -1) / 2.0
			
			var instance = wallSegment_prefab.instantiate()
			corner.add_child(instance)
			
			instance.rotation = direction.angle()
			instance.set_global_position(midpoint)
			instance.scale.x = length / 617
			objectsInside[0].segments.append(instance)
			
	food -= 50
	wood -= 50
	stone -= 50
	
func _on_combatBuildingMenu_button_pressed():
	var what = "HUH"
func _on_combatBuildingMenu_button_released():
	combatBuildingMenu.visible = true
	resourceBuildingMenu.visible = false
	
func _on_closeCombatMenu_button_pressed():
	var what = "HUH"
func _on_closeCombatMenu_button_released():
	combatBuildingMenu.visible = false
	
	
func _on_resourceBuildingMenu_button_pressed():
	var what = "HUH"
	
func _on_resourceBuildingMenu_button_released():
	resourceBuildingMenu.visible = true
	combatBuildingMenu.visible = false

func _on_closeResourceMenu_button_pressed():
	var what = "huh"


func _on_closeResourceMenu_button_released():
	resourceBuildingMenu.visible = false

func _on_manageCaravans_button_pressed():
	if RCLICK_ResourceHub.visible == false:
		return
	
	
func _on_manageCaravans_button_released():
	if RCLICK_ResourceHub.visible == false:
		return
	var resourceHubAtLocation = grid.probe(RCLICK_ResourceHub.get_global_position()).objectsInside[0]
	resourceHubAtLocation.manageCaravanMenu.visible = true
	resourceHubAtLocation.manageCaravanMenu.set_global_position(RCLICK_ResourceHub.get_global_position())
	
	
	RCLICK_ResourceHub.visible = false
	
#Start dragging the farm if has enough money
func _on_farm_button_pressed():
	if food < 500 or stone < 500 or wood < 500:
		print("Ya Broke")
		return
	
	
	beginDragging("Farm")
	

#finishes dragging the farm and places
func _on_farm_button_released():
	
	if buildingDraggin != "Farm" or wood < 500 or stone < 500 or food < 500:
		buildingDraggin = null
		return
	if finishDragging("Farm") == false:
		return
	food -= 500
	wood -= 500
	stone -= 500
	

#starts draggin the lumberJack
func _on_lumberJack_button_pressed():
	if food < 500 or stone < 500 or wood < 500:
		print("Ya Broke")
		return
	beginDragging("LumberJack")
	

#finishes dragging the lumberJack and places
func _on_lumberJack_button_released():
	
	if buildingDraggin != "LumberJack" or wood < 500 or stone < 500 or food < 500:
		buildingDraggin = null
		return
	if finishDragging("LumberJack") == false:
		return
	food -= 500
	wood -= 500
	stone -= 500
	
#Starts draggin the Stone mine
func _on_stoneMine_button_pressed():
	if food < 500 or stone < 500 or wood < 500:
		print("Ya Broke")
		return
	
	
	beginDragging("StoneMine")
	

#finishes dragging the Stone Mine and places
func _on_stoneMine_button_released():
	
	if buildingDraggin != "StoneMine" or wood < 500 or stone < 500 or food < 500:
		buildingDraggin = null
		return
	if finishDragging("StoneMine") == false:
		return
	food -= 500
	wood -= 500
	stone -= 500


#Start dragging the resource hub if has enough money
func _on_resourceHub_button_pressed():
	if food < 5000 or stone < 5000 or wood < 5000:
		print("Ya Broke")
		return
	
	beginDragging("ResourceHub")
	

#finishes dragging the resource hub and places
func _on_resourceHub_button_released():
	
	if buildingDraggin != "ResourceHub" or wood < 5000 or stone < 5000 or food < 5000:
		buildingDraggin = null
		return
	if finishDragging("ResourceHub") == false:
		return
	print("Added Resource Hub")
	
	food -= 5000
	wood -= 5000
	stone -= 5000
	
func _on_barracks_button_pressed():
	if food < 1000 or wood < 1000 or stone < 1000:
		print("Ya Broke")
		return
	beginDragging("Barracks")
	
func _on_barracks_button_released():
	
	if buildingDraggin != "Barracks" or food < 1000 or wood < 1000 or stone < 1000:
		buildingDraggin = null
		return
	
	if finishDragging("Barracks") == false:
		return
	var tempVector = grid.coord_to_axial_hex(get_global_mouse_position())
	tempVector.x += 1
	grid.update_grid(tempVector, 1, ["Training Ground"])
	
	food -= 1000
	wood -= 1000
	stone -= 1000
	
	
func _process(delta): #runs every tick
	cleanBuildings()
	hoveringText()
	
	#Opens up the right click menu
	if Input.is_action_just_pressed("right_click_menu"):
		if grid.probe(get_global_mouse_position()).objectsInside.size() > 0 and grid.probe(get_global_mouse_position()).objectsInside[0].type == "ResourceHub":
			RCLICK_ResourceHub.set_global_position(get_global_mouse_position())
			RCLICK_ResourceHub.visible = true
		else:
			print("We vibin?")
			RCLICK_ResourceHub.visible = false
		
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
			


func hoveringText():
	for button in combatButtons:
		if button[0].is_hovered():
			button[1].visible = true
		else:
			button[1].visible = false
	for button in resourceButtons:
		if button[0].is_hovered():
			button[1].visible = true
		else:
			button[1].visible = false
	if combatBuildingMenuButton.is_hovered():
		combatBuildingLabel.visible = true
	else:
		combatBuildingLabel.visible = false
	
	if resourceBuildingMenuButton.is_hovered():
		resourceBuildingLabel.visible = true
	else:
		resourceBuildingLabel.visible = false
func freeBuilding(ID):
	
	for i in range(buildings.size()):
		if buildings[i].BUILDING_UNIQUE_ID == ID:
			grid.update_grid(buildings[i].pos, 0, [])
			var object = buildings.pop_at(i)
			if object.type == "WallCorner":
				while object.segments.size() > 0:
					object.segments.pop_at(0).queue_free()
					
			
			object.queue_free()
			return

func beginDragging(buildingName):
	
	buildingDraggin = buildingName
	#money -= 500
	#Adding the farm to be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = null
	#Convert this into a list of each prefab, then have buildingName 
	#passed in as an int representing its index in the list
	
	if buildingName == "Farm":
		instance = farm_prefab.instantiate()
	elif buildingName == "ResourceHub":
		instance = resourceHub_prefab.instantiate()
	elif buildingName == "StoneMine":
		instance = stoneMine_prefab.instantiate()
	elif buildingName == "LumberJack":
		instance = lumberJack_prefab.instantiate()
	elif buildingName == "Barracks":
		instance = barracks_prefab.instantiate()
	elif buildingName == "WallCorner":
		instance = wallCorner_prefab.instantiate()
	 #New FAKE money farm
	
	instance.fake = true
	instance.type = buildingName
	#instance.$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	#var toAdd = ["Farm", get_global_mouse_position(), instance]
	instance.BUILDING_UNIQUE_ID = buildingIDTracker
	buildingIDTracker += 1
	instance.controller = self
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance)
	 
func finishDragging(buildingName):
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !is_placeable(buildings[buildings.size() - 1]):
		buildings.pop_back().queue_free()
		return false
	buildings[buildings.size() - 1].fake = false
	buildings[buildings.size() - 1].global_position = grid.hex_center(get_global_mouse_position())
	buildings[buildings.size() - 1].pos = grid.coord_to_axial_hex(get_global_mouse_position())
	
	grid.update_grid(grid.coord_to_axial_hex(get_global_mouse_position()), 2, [buildings[buildings.size() - 1]])
	return true


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
