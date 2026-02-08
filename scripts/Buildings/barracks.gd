extends Building
@onready var shapey = $RigidBody2D/Sprite2D
@onready var HPBar = $HP_BAR

var spawnTimer = 0 #Tracking when to give troops



#func _ready(): #I EXIST!

	
func spawn(p, delta, position, grid): #Generates meeple every 5 seconds
	if self.fake: return
	
	spawnTimer += delta
	if spawnTimer >= 5:
		var tempVector = position
		tempVector.x += 1
		
		p.spawn_meeple(tempVector)
		
		#p.group[0].push_back(instance)
		
		spawnTimer = 0
	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
