extends Building

@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var target = null
const DMG = 3
const RANGE = 5
func attack():
	if target == null:
		return
	target.hp -= DMG
	
func getTarget(grid):
	print("-------------")
	var tempDirs = []
	
	for d in grid.HEX_DIRS:
		for h in grid.HEX_DIRS:
			tempDirs.append(d + h)
	
	for t in tempDirs:
		print(t)
	print("--------------")
#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()


	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
