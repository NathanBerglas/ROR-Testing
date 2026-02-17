extends meeple


var attackTimer = 0
var attackRange = 1

func _ready():
	self.rb = $RigidBody2D
	self.sprite = $RigidBody2D/Sprite2D
	self.label = $RigidBody2D/Label
	self.type = "Infantry"


func _process(delta): #runs on each meeple every tick
	label.text = str(HP)
	
	
	if attackTarget:
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
		if target.type == "Meeple":
			if path == null:
				target.HP -= HP * 2
			else:
				target.HP -= int(HP)
			
			if target.HP <= 0:
				attackTarget = null
			
			
		else:
			if path == null:
				target.hp -= size * 10
			else:
				target.hp -= int(size * 5)
			
			if target.hp <= 0:
				attackTarget = null
				
		
		
		
func inAttackRange(target):
	if target == null:
		return false
	var distToTarget = pos - target
	
	for v in HEX_DIRS: #Need to change based on varying range
		if distToTarget == v:
			return true
			
	return false
	
