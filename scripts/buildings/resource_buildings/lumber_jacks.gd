extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var woodTimer = 0 #Tracking when to give $$$



#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()

var size = 1

const HEX_SHAPE := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

func _ready():
	set_size(size)
	

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
