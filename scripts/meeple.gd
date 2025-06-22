extends Node2D

@export var area_2d: Area2D

func _process(delta):
	resolve_overlap()

# Avoids overlapping
func resolve_overlap():
	var radius = 64
	for touching in area_2d.get_overlapping_areas():
		# Nudge away
		print("Nudged!")
		var angle_to = self.get_angle_to(touching.global_position)
		global_position = touching.global_position - Vector2(cos(angle_to),sin(angle_to))*radius
