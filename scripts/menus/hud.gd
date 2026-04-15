extends CanvasLayer

var farmButtonPos = Vector2(470.0, 1.0)


func updateFood(food): #Updates the money displayed
	$Food.text = "Food: " + str(food) 
	
func updateWood(lumber): #Updates the money displayed
	$Lumber.text = "Lumber: " + str(lumber) 
	
func updateStone(stone): #Updates the money displayed
	$Stone.text = "Stone: " + str(stone) 
