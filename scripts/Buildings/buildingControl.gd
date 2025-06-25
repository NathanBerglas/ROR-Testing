extends Node2D
@onready var hud = $buildingHud
@onready var farmButton = $buildingHud/FarmButton
@export var farm_prefab: PackedScene

#Players Money
var money = 1000

#Checking what type of building the player is dragging
var buildingDraggin = null

#A list of the buildings owned
#Format is: ["Building Name", Vector(Building Pos), Building itself]
var buildings = [] 

func _ready(): #Runs on start, connects buttons
	farmButton.button_down.connect(_on_farm_button_pressed)
	farmButton.button_up.connect(_on_farm_button_released)
	

#Start dragging the farm if has enough money
func _on_farm_button_pressed():
	if money < 500:
		return
	buildingDraggin = "Farm"
	

#finishes dragging the farm and places
func _on_farm_button_released():
	if buildingDraggin != "Farm":
		return
	money -= 500
	hud.updateMoney(money) #updates money amount
	farmButton.position = hud.farmButtonPos
	buildingDraggin = null

	var instance = farm_prefab.instantiate() #New money farm
	var toAdd = ["Farm", get_global_mouse_position(), instance]
	
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	buildings.push_back(toAdd) #Adding building to list of buildings owned
	

func _process(delta): #runs every tick
	if buildingDraggin == "Farm": #Code actually dragging the farm around
		var vector = get_global_mouse_position()
		vector.x -= 60
		vector.y -= 60
		farmButton.position = vector
	

	for m in buildings: #Doing tick stuff for each building
		if m[0] == "Farm":
			m[2].generateIncome(self, delta)

	

func addMoney(moneyChange): #Changing money
	money += moneyChange
	hud.updateMoney(money)
	
	
	
