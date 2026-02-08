extends Building
@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR




#func _ready():
	#$MultiplayerSynchronizer.set_multiplayer_authority()


	
func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
