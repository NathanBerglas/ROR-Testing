extends Building
@onready var shapey = $RigidBody2D/Sprite2D


var moneyTimer = 0 #Tracking when to give $$$

var fake = false #Check if this is dragging or NAH

func _ready(): #I EXIST!
	if !fake: print("Farm ready to grow food!")



func generateIncome(p, delta): #Generates income every 10 seconds
	if fake: return
	
	moneyTimer += delta
	if moneyTimer >= 10:
		p.addMoney(200)
		moneyTimer = 0
	

#Dont ask Jacob WTF this code is. ChatGPT wrote is
func is_placeable() -> bool: #Only for if a building is FAKE
	if !fake: return false #<- cept this line
	print("Whats up")
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	query.shape = $RigidBody2D/BodyForFarm.shape
	query.transform = $RigidBody2D/BodyForFarm.global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [$RigidBody2D.get_rid()]
	var result = space_state.intersect_shape(query)
	for m in result:
		print("Hit: ", m.collider.name)
	return result.is_empty()  # True = no collision, so placeable
