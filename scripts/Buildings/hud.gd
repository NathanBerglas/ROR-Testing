extends CanvasLayer

var farmButtonPos = Vector2(470.0, 1.0)

func updateMoney(money):
	$Money.text = "Money: " + str(money) 
