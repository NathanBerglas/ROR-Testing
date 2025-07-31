extends Building
@onready var shapey = $RigidBody2D/Sprite2D


var spawnTimer = 0 #Tracking when to give troops



func _ready(): #I EXIST!
	if !self.fake:
		print("Hi")


func spawn(p, delta,_pos): #Generates meeple every 5 seconds
	if self.fake: return
	
	spawnTimer += delta
	if spawnTimer >= 5:
		var instance = p.meeple_prefab.instantiate()
		instance.UNIQUEID = p.MEEPLE_ID_COUNTER
		p.MEEPLE_ID_COUNTER += 1
		
		add_child(instance)
		p.set_id(instance)
		
		var newMeeple = []
		newMeeple.push_back(instance.UNIQUEID)
		newMeeple.push_back(instance.global_position)
		newMeeple.push_back(instance.HP)
			
		p.unorderedMeeples.push_back(newMeeple)
		p.group[0].push_back(instance)
		
		spawnTimer = 0
	
