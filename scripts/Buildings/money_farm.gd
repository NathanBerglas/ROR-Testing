extends Building

var moneyTimer = 0


func _ready():
	print("Farm ready to grow food!")



func generateIncome(p, delta):
	moneyTimer += delta
	if moneyTimer >= 10:
		p.addMoney(200)
		moneyTimer = 0
	
