extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var cropsTimer = 0 #Tracking when to give $$$

var collectedFood = 0

#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()


var size = 1

const HEX_SHAPE := [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

func _ready():
	set_size(size)
	
func generateFood(p, delta): #Generates income every 10 seconds
	if self.fake: return
	
	cropsTimer += delta
	if cropsTimer >= 10:
		p.addFood(200)
		collectedFood += 200
		
		cropsTimer = 0

	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
