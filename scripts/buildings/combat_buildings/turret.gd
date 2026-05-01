extends Building

@onready var shapey = $Sprite2D
@onready var HPBar = $HP_BAR

var target = null

const DMG = 1
const SECONDS_PER_ATTACK = 2
var time_since_last_attack = 0

var size = 0.9
const HEX_SHAPE := [
	Vector2i(0, 1),
	Vector2i(0, 0),
	Vector2i(-1, 1)]


func _ready():
	set_size(size)
	#$MultiplayerSynchronizer.set_multiplayer_authority()


func attack(delta):
	time_since_last_attack += delta
	if time_since_last_attack > SECONDS_PER_ATTACK:
		time_since_last_attack = 0
		if target == null:
			return
		target.update_hp(-DMG)
		if !is_instance_valid(target): # was just killed
			target = null


func getTarget(grid):
	var visited_hexs = []
	for d in grid.HEX_DIRS:
		for h in grid.HEX_DIRS:
			var tile_pos = self.pos + d + h
			if !(tile_pos in visited_hexs):
				visited_hexs.append(tile_pos)
				var tile = grid.axial_probe(tile_pos)
				if len(tile.objectsInside) > 0 and tile.objectsInside[0] is meeple and tile.objectsInside[0].player_id != player_id:
						target = tile.objectsInside[0]


func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
