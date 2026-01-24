extends Building
@onready var shapey = $RigidBody2D/Sprite2D
@onready var HPBar = $HP_BAR

var moneyTimer = 0 #Tracking when to give $$$



#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()



func generateIncome(p, delta): #Generates income every 10 seconds
	if self.fake: return
	
	moneyTimer += delta
	if moneyTimer >= 10:
		p.addMoney(200)
		moneyTimer = 0
	
	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
