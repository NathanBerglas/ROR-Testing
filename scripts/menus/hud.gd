extends CanvasLayer

var farmButtonPos = Vector2(470.0, 1.0)


func updateFood(food):  #Updates the food displayed
	$ResourcesV/ResourcesMain/Food.text = str(food)


func updateWood(lumber):  #Updates the wood displayed
	$ResourcesV/ResourcesMain/Lumber.text = str(lumber)


func updateStone(stone):  #Updates the stone displayed
	$ResourcesV/ResourcesMain/Stone.text = str(stone)


func updateIron(iron):  #Updates the iron displayed
	$ResourcesV/ResourcesMain2/Iron.text = str(iron)


func updateTreasury(money):  #Updates the money displayed
	$ResourcesV/ResourcesMain2/Treasury.text = str(money)
