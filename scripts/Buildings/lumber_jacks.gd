extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var woodTimer = 0 #Tracking when to give $$$



#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()



func generateWood(p, delta): #Generates income every 10 seconds
	if self.fake: return
	
	woodTimer += delta
	if woodTimer >= 10:
		p.addWood(200)
		woodTimer = 0
	
	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
