extends meeple


var attackTimer = 0
var attackRange = 1

func _ready():
	super._ready()
	self.sprite = $Sprite2D
	self.type = "Infantry"
	

func _process(delta): #runs on each meeple every tick
	#label.text = str(self.HP)
	if attackTarget:
		if attackTarget.type == "Infantry":
			if inAttackRange(attackTarget.path[0]):
				attack(attackTarget, delta)
		else:
			if attackTarget.superType == "Building":
				var in_range = false
				if inAttackRange(attackTarget.pos):
					in_range = true
				for h in attackTarget.HEX_SHAPE:
					if inAttackRange(attackTarget.pos + h):
						in_range = true
				if in_range:
					attack(attackTarget, delta)
			else:
				if inAttackRange(attackTarget.pos):
					attack(attackTarget, delta)
	#if (path != null and shouldBeMoving): #if a meeple has somewhere to go, goes to it
		#_go_to_target(delta)
	
	#if dest != null and closeEnough(): #meeple reaches destination
		#dest = null
	
func get_id():
	return self.UNIQUEID
func set_id(id):
	self.UNIQUEID = id

func attack(target, delta):
	attackTimer += delta
	if attackTimer >= 1:
		attackTimer = 0
		if target.type == "Infantry":
			if shouldBeMoving:
				target.update_hp(-HP * 2)
			else:
				target.update_hp(-HP)
			if target.HP <= 0:
				attackTarget = null		
		else:
			if shouldBeMoving:
				target.hp -= HP * 10
				print('attacked for ', -HP * 10, " damage")
			else:
				target.hp -= int(HP * 5)
			if target.hp <= 0:
				attackTarget = null


func inAttackRange(target):
	if target == null:
		return false
	var distToTarget = path[0] - target
	for v in HEX_DIRS: #Need to change based on varying range
		if distToTarget == v:
			return true
			
	return false
	
