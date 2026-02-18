extends Building

@onready var shapey = $RigidBody2D/Sprite2D
@onready var HPBar = $HP_BAR


var segments = []


#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()


func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
