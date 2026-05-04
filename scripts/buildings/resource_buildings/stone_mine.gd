extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var stoneTimer = 0  #Tracking when to give $$$

var saved_stone = 0

#func _ready():
#$MultiplayerSynchronizer.set_multiplayer_authority()

var size = 1
const HEX_SHAPE := [Vector2i(0, 0)]


func _ready():
	set_size(size)
	type = "stoneMine"


func generateStone(p, delta):  #Generates income every 10 seconds
	if self.fake:
		return

	stoneTimer += delta
	if stoneTimer >= 10:
		saved_stone += 200
		stoneTimer = 0


func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
