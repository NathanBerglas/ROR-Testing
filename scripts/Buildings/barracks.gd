extends Building
@onready var shapey = $RigidBody2D/Sprite2D
@onready var HPBar = $HP_BAR

var spawnTimer = 0 #Tracking when to give troops



#func _ready(): #I EXIST!

	
func spawn(p, delta, position, grid): #Generates meeple every 5 seconds
	if self.fake: return
	
	spawnTimer += delta
	if spawnTimer >= 5:
		var instance = p.meeple_prefab.instantiate()
		instance.UNIQUEID = p.MEEPLE_ID_COUNTER
		p.MEEPLE_ID_COUNTER += 1
		var tempVector = position
		tempVector.x += 1
		
		add_child(instance)
		p.set_id(instance)
		
		instance.set_global_position(grid.axial_hex_to_coord(tempVector))
			
		p.unorderedMeeples.push_back(instance)
		#p.group[0].push_back(instance)
		
		spawnTimer = 0
	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
