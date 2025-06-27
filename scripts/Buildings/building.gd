extends Node2D
class_name Building 

@onready var building_type := str(null)  # must be overridden

#A list of the costs of each building
var buildingCosts = [["Barracks", 1000], ["Farm", 500]] 

var fake = false #Check if this is dragging or NAH


#Dont ask Jacob WTF this code is. ChatGPT wrote is
func is_placeable() -> bool: #Only for if a body is FAKE
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	query.shape = $RigidBody2D/CollisionShape2D.shape
	query.transform = $RigidBody2D/CollisionShape2D.global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [$RigidBody2D.get_rid()]
	var result = space_state.intersect_shape(query)
	return result.is_empty()  # True = no collision, so placeable
