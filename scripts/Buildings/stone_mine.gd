extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var stoneTimer = 0 #Tracking when to give $$$



#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()



func generateStone(p, delta): #Generates income every 10 seconds
	if self.fake: return
	
	stoneTimer += delta
	if stoneTimer >= 10:
		p.addStone(200)
		stoneTimer = 0
	
	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
