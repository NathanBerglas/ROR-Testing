extends Node2D
@onready var hud = $buildingHud
@onready var farmButton = $buildingHud/FarmButton
@export var farm_prefab: PackedScene

var money = 1000

var buildingDraggin = null
var buildings = []

func _ready():
	farmButton.button_down.connect(_on_farm_button_pressed)
	farmButton.button_up.connect(_on_farm_button_released)
	

func _on_farm_button_pressed():
	if money < 500:
		return

	buildingDraggin = "Farm"
	
	
func _on_farm_button_released():
	if buildingDraggin != "Farm":
		return
	money -= 500
	hud.updateMoney(money)
	farmButton.position = hud.farmButtonPos
	buildingDraggin = null

	var instance = farm_prefab.instantiate()
	var toAdd = ["Farm", get_global_mouse_position(), instance]
	instance.global_position = get_global_mouse_position()
	add_child(instance) #Adding the instance
	buildings.push_back(toAdd) #Adding building to list of buildings owned
	
func _process(delta):
	if buildingDraggin == "Farm":
		var vector = get_global_mouse_position()
		vector.x -= 60
		vector.y -= 60
		farmButton.position = vector
	

	for m in buildings:
		if m[0] == "Farm":
			m[2].generateIncome(self, delta)

	

func addMoney(moneyChange):
	money += moneyChange
	hud.updateMoney(money)
	
	
	
