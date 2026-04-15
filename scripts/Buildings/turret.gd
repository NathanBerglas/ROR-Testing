extends Building

@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var target = null
const DMG = 3
const RANGE = 5

var size = 0.9
const HEX_SHAPE := [

	Vector2i(0, 1),
	Vector2i(-1, 1)
	#Vector2i(1, 1),
]


func _ready():
	set_size(size)
	
func attack():
	if target == null:
		return
	target.hp -= DMG
	
func getTarget(grid):
	#print("-------------")
	var tempDirs = []
	
	for d in grid.HEX_DIRS:
		for h in grid.HEX_DIRS:
			tempDirs.append(d + h)
	
	#for t in tempDirs:
		#print(t)
	#print("--------------")
#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()


	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
