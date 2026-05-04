extends Building
@onready var shapey = $RigidBody2D/Sprite2D
@onready var HPBar = $HP_BAR

var spawnTimer = 0  #Tracking when to give troops

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


func spawn(p, delta, spawn_pos, grid):  #Generates meeple every 5 seconds
	if self.fake:
		return

	spawnTimer += delta
	if spawnTimer >= 5:
		var tempVector = spawn_pos
		tempVector.x += 1

		p.spawn_meeple(grid.axial_hex_to_coord(tempVector))

		#p.group[0].push_back(instance)

		spawnTimer = 0


func updateHPBar():
	if self.fake:
		HPBar.visible = false
	else:
		HPBar.visible = true
	HPBar.value = self.hp
