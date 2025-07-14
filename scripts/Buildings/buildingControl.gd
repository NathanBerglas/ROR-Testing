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
var playerID = 0


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
	#instance.$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	var toAdd = ["Farm", get_global_mouse_position(), instance]
	
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(toAdd) 
	

#finishes dragging the farm and places
func _on_farm_button_released():
	
	if buildingDraggin != "Farm" or money < 500:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !buildings[buildings.size() - 1][2].is_placeable():
		buildings.pop_back()[2].queue_free()
		return
	buildings[buildings.size() - 1][2].fake = false
	money -= 500
	
func _process(delta): #runs every tick
	if buildingDraggin != null: #Code actually dragging the farm around
		buildings[buildings.size() - 1][2].global_position = get_global_mouse_position()
		if !buildings[buildings.size() - 1][2].is_placeable():
			buildings[buildings.size() - 1][2].shapey.modulate = Color(250, 0, 4) #RED
		else:
			buildings[buildings.size() - 1][2].shapey.modulate = Color(1, 1, 1)  # Reset to white

	for m in buildings: #Doing tick stuff for each building
		if m[0] == "Farm" and !m[2].fake:
			m[2].generateIncome(self, delta)
		elif m[0] == "Barracks" and !m[2].fake:
			m[2].spawn(self.teammates[0],delta,m[1])
	hud.updateMoney(money) #updates money amount
	

func addMoney(moneyChange): #Changing money
	money += moneyChange
	hud.updateMoney(money)
	
func _on_barracks_button_pressed():
	if money < 1000:
		print("Ya Broke")
		return
	buildingDraggin = "Barracks"

	#Adding the barracksto be dragged to the list of buildings
	# hashtag-No way this will cause errors in the future
	var instance = barracks_prefab.instantiate() #New FAKE money farm
	instance.fake = true
	var toAdd = ["Barracks", Vector2(0,0), instance]
	
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	
	buildings.push_back(toAdd) 
func _on_barracks_button_released():
	
	if buildingDraggin != "Barracks" or money < 1000:
		buildingDraggin = null
		return
	buildingDraggin = null
	
	#If not placeable, REMOVED
	if !buildings[buildings.size() - 1][2].is_placeable():
		buildings.pop_back()[2].queue_free()
		return
	buildings[buildings.size() - 1][2].fake = false
	buildings[buildings.size() - 1][1] = get_global_mouse_position()
	print("Barracks Placed: " + str(buildings[buildings.size() - 1][2].get_global_position()))
	money -= 1000
	
