extends CanvasLayer

var farmButtonPos = Vector2(470.0, 1.0)


func updateFood(food): #Updates the food displayed
	$Food.text = "Food: " + str(food) 
	
func updateWood(lumber): #Updates the wood displayed
	$Lumber.text = "Lumber: " + str(lumber) 
	
func updateStone(stone): #Updates the stone displayed
	$Stone.text = "Stone: " + str(stone) 
	
func updateTreasury(money): #Updates the money displayed
	$Treasury.text = "Money: " + str(money) 
