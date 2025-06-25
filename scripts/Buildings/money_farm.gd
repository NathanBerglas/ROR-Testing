extends Building

var moneyTimer = 0


func _ready(): #I EXIST!
	print("Farm ready to grow food!")



func generateIncome(p, delta): #Generates income every 10 seconds
	moneyTimer += delta
	if moneyTimer >= 10:
		p.addMoney(200)
		moneyTimer = 0
	
