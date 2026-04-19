extends Building

@onready var shapey = $RigidBody2D/Sprite2D
@onready var HPBar = $HP_BAR


var segments = []

var size = 0.8
const HEX_SHAPE := [
	Vector2i(0, 0),
]

func _ready():
	set_size(size)
	
#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()


func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
