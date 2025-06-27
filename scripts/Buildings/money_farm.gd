extends Building
@onready var shapey = $RigidBody2D/Sprite2D


var moneyTimer = 0 #Tracking when to give $$$



func _ready(): #I EXIST!
	if !self.fake: print("Farm ready to grow food!")



func generateIncome(p, delta): #Generates income every 10 seconds
	if self.fake: return
	
	moneyTimer += delta
	if moneyTimer >= 10:
		p.addMoney(200)
		moneyTimer = 0
	
