extends Building
@onready var shapey = $RigidBody2D/Sprite2D


var spawnTimer = 0 #Tracking when to give troops



func _ready(): #I EXIST!
	if !self.fake:
		print("Hi")


func spawn(p, delta,pos): #Generates income every 10 seconds
	if self.fake: return
	
	spawnTimer += delta
	if spawnTimer >= 5:
		var instance = p.meeple_prefab.instantiate()
		
		add_child(instance)
		p.set_id(instance)
		p.group[0].push_back(instance)
		
		spawnTimer = 0
	
