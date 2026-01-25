extends Node2D
@onready var hud = $buildingHud
@onready var farmButton = $buildingHud/FarmButton
@onready var barracksButton = $buildingHud/BarracksButton
@export var farm_prefab: PackedScene
@export var barracks_prefab: PackedScene



#Players Money
var money = 10000

#Checking what type of building the player is dragging
var buildingDraggin = null

#A list of the buildings owned
#Format is: ["Building Name", Vector(Building Pos), Building itself]
var buildings = [] 

var teammates = [] #list of teammates
var grid # the grid controller
var playerID = 0
var idTracker = 0

func _ready(): #Runs on start, connects buttons
	farmButton.button_down.connect(_on_farm_button_pressed)
	farmButton.button_up.connect(_on_farm_button_released)
	farmButton.custom_minimum_size = Vector2(121.6,120)
	
	barracksButton.button_down.connect(_on_barracks_button_pressed)
	barracksButton.button_up.connect(_on_barracks_button_released)
	barracksButton.custom_minimum_size = Vector2(121.6,120)
	
	#print(playerID)
	

#Start dragging the farm if has enough money
func _on_farm_button_pressed():
	if money < 500:
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
	instance.BUILDING_UNIQUE_ID = idTracker
	idTracker += 1
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	

#finishes dragging the farm and places
func _on_farm_button_released():
	
	if buildingDraggin != "Farm" or money < 500:
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
	money -= 500
	
func _on_barracks_button_pressed():
	if money < 1000:
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
	instance.BUILDING_UNIQUE_ID = idTracker
	idTracker += 1
	add_child(instance) #Adding the instance
	
	buildings.push_back(instance) 
	
func _on_barracks_button_released():
	
	if buildingDraggin != "Barracks" or money < 1000:
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
	
	money -= 1000
	
	
func _process(delta): #runs every tick
	cleanBuildings()
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
			m.generateIncome(self, delta)
		elif m.type == "Barracks" and !m.fake:
			m.spawn(self.teammates[0],delta,m.pos, grid)
	hud.updateMoney(money) #updates money amount
	

func addMoney(moneyChange): #Changing money
	money += moneyChange
	hud.updateMoney(money)
	
func takeDamage(b, x):
	b.hp -= x
	
func is_placeable(_building) -> bool: #Only for if a body is FAKE
	
	
	if grid.probe(get_global_mouse_position()).classification == 0:
		
		return true
	else:
		return false
		


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
