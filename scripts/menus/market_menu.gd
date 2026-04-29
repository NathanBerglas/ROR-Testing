extends Control

const FLAG_VERBOSE = true

@onready var building_control = self.get_parent().get_parent()
@onready var close_button = $Background/Close
@onready var treasure_label = $Background/Market/Treasury/TreasuryLabel

# Essentials
@onready var foodLabel = $Background/Market/EssentialGrid/FoodLabel
@onready var foodBuyButton = $Background/Market/EssentialGrid/FoodBuy
@onready var foodSellButton = $Background/Market/EssentialGrid/FoodSell
@onready var foodAmount = $Background/Market/EssentialGrid/FoodAmount
@onready var foodPrice = $Background/Market/EssentialGrid/FoodPrice
@onready var foodPricePerUnit = $Background/Market/EssentialGrid/FoodPricePerUnit

@onready var woodLabel = $Background/Market/EssentialGrid/WoodLabel
@onready var woodBuyButton = $Background/Market/EssentialGrid/WoodBuy
@onready var woodSellButton = $Background/Market/EssentialGrid/WoodSell
@onready var woodAmount = $Background/Market/EssentialGrid/WoodAmount
@onready var woodPrice = $Background/Market/EssentialGrid/WoodPrice
@onready var woodPricePerUnit = $Background/Market/EssentialGrid/WoodPricePerUnit

@onready var stoneLabel = $Background/Market/EssentialGrid/StoneLabel
@onready var stoneBuyButton = $Background/Market/EssentialGrid/StoneBuy
@onready var stoneSellButton = $Background/Market/EssentialGrid/StoneSell
@onready var stoneAmount = $Background/Market/EssentialGrid/StoneAmount
@onready var stonePrice = $Background/Market/EssentialGrid/StonePrice
@onready var stonePricePerUnit = $Background/Market/EssentialGrid/StonePricePerUnit

@onready var ironLabel = $Background/Market/EssentialGrid/IronLabel
@onready var ironBuyButton = $Background/Market/EssentialGrid/IronBuy
@onready var ironSellButton = $Background/Market/EssentialGrid/IronSell
@onready var ironAmount = $Background/Market/EssentialGrid/IronAmount
@onready var ironPrice = $Background/Market/EssentialGrid/IronPrice
@onready var ironPricePerUnit = $Background/Market/EssentialGrid/IronPricePerUnit

@onready var rubyLabel = $Background/Market/LuxuryGrid/RubyLabel
@onready var rubyBuyButton = $Background/Market/LuxuryGrid/RubyBuy
@onready var rubySellButton = $Background/Market/LuxuryGrid/RubySell
@onready var rubyAmount = $Background/Market/LuxuryGrid/RubyAmount
@onready var rubyPrice = $Background/Market/LuxuryGrid/RubyPrice
@onready var rubyPricePerUnit = $Background/Market/LuxuryGrid/RubyPricePerUnit

@onready var diamondLabel = $Background/Market/LuxuryGrid/DiamondLabel
@onready var diamondBuyButton = $Background/Market/LuxuryGrid/DiamondBuy
@onready var diamondSellButton = $Background/Market/LuxuryGrid/DiamondSell
@onready var diamondAmount = $Background/Market/LuxuryGrid/DiamondAmount
@onready var diamondPrice = $Background/Market/LuxuryGrid/DiamondPrice
@onready var diamondPricePerUnit = $Background/Market/LuxuryGrid/DiamondPricePerUnit


func _ready():
	close_button.pressed.connect(_on_close_pressed)
	
	foodBuyButton.button_up.connect(_on_food_buy)
	foodSellButton.button_up.connect(_on_food_sell)
	foodAmount.value_changed.connect(_on_food_amount_changed)
	
	woodBuyButton.button_up.connect(_on_wood_buy)
	woodSellButton.button_up.connect(_on_wood_sell)
	woodAmount.value_changed.connect(_on_wood_amount_changed)
	
	stoneBuyButton.button_up.connect(_on_stone_buy)
	stoneSellButton.button_up.connect(_on_stone_sell)
	stoneAmount.value_changed.connect(_on_stone_amount_changed)
	
	ironBuyButton.button_up.connect(_on_iron_buy)
	ironSellButton.button_up.connect(_on_iron_sell)
	ironAmount.value_changed.connect(_on_iron_amount_changed)
	
	rubyBuyButton.button_up.connect(_on_ruby_buy)
	rubySellButton.button_up.connect(_on_ruby_sell)
	rubyAmount.value_changed.connect(_on_ruby_amount_changed)
	
	diamondBuyButton.button_up.connect(_on_diamond_buy)
	diamondSellButton.button_up.connect(_on_diamond_sell)
	diamondAmount.value_changed.connect(_on_diamond_amount_changed)


func _on_close_pressed():
	visible = false
	building_control.hud.visible = true


func open():
	visible = true
	update_ui()


func update_ui():
	treasure_label.text = "Treasury Amount: $" + str(building_control.money)
	
	foodLabel.text = "Food: " + str(building_control.food)
	foodPricePerUnit.text = "Price per 1k Units: $" + str(building_control.food_price)
	
	woodLabel.text = "Wood: " + str(building_control.wood)
	woodPricePerUnit.text = "Price per 1k Units: $" + str(building_control.wood_price)
	
	stoneLabel.text = "Stone: " + str(building_control.stone)
	stonePricePerUnit.text = "Price per 1k Units: $" + str(building_control.stone_price)
	
	ironLabel.text = "Iron: " + str(building_control.iron)
	ironPricePerUnit.text = "Price per 1k Units: $" + str(building_control.iron_price)
	
	rubyLabel.text = "Ruby: " + str(building_control.ruby)
	rubyPricePerUnit.text = "Price per 1k Units: $" + str(building_control.ruby_price)
	
	diamondLabel.text = "Diamond: " + str(building_control.diamond)
	diamondPricePerUnit.text = "Price per 1k Units: $" + str(building_control.diamond_price)


func _trade(resourceID, isBuying):
	var amount_value = 0
	var price = 1
	var units_in_inventory = 0
	var price_per_X: float = 1.0 # Must also be set in _on_resource_amount_changed
	if resourceID == 0: # food
		amount_value = foodAmount.value
		price = building_control.food_price
		units_in_inventory = building_control.food
		price_per_X = 1000.0
	elif resourceID == 1: # wood
		amount_value = woodAmount.value
		price = building_control.wood_price
		units_in_inventory = building_control.wood
		price_per_X = 1000.0
	elif resourceID == 2: # stone
		amount_value = stoneAmount.value
		price = building_control.stone_price
		units_in_inventory = building_control.stone
		price_per_X = 1000.0
	elif resourceID == 3: # iron
		amount_value = ironAmount.value
		price = building_control.iron_price
		units_in_inventory = building_control.iron
		price_per_X = 1000.0
	elif resourceID == 4: # ruby
		amount_value = rubyAmount.value
		price = building_control.ruby_price
		units_in_inventory = building_control.ruby
		price_per_X = 1.0
	elif resourceID == 5: # diamond
		amount_value = diamondAmount.value
		price = building_control.diamond_price
		units_in_inventory = building_control.diamond
		price_per_X = 1.0
		
	var trade_quantity = 0
	if isBuying == 1: # Buying
		trade_quantity = clamp(amount_value, 0, int(price_per_X * building_control.money / price)) # What they can afford
	elif isBuying == -1: # Selling
		trade_quantity = clamp(amount_value, 0, units_in_inventory) # What they can afford
		
	building_control.money -= int(1. / price_per_X * price * trade_quantity) * isBuying
	if resourceID == 0: #food
		building_control.food += int(trade_quantity) * isBuying
		_on_food_amount_changed(0)
	elif resourceID == 1: #wood
		building_control.wood += int(trade_quantity) * isBuying
		_on_wood_amount_changed(0)
	elif resourceID == 2: #stone
		building_control.stone += int(trade_quantity) * isBuying
		_on_stone_amount_changed(0)
	elif resourceID == 3: #iron
		building_control.iron += int(trade_quantity) * isBuying
		_on_iron_amount_changed(0)
	elif resourceID == 4: #ruby
		building_control.ruby += int(trade_quantity) * isBuying
		_on_ruby_amount_changed(0)
	elif resourceID == 5: #diamond
		building_control.diamond += int(trade_quantity) * isBuying
		_on_diamond_amount_changed(0)
		
	update_ui()
	return


func _on_food_buy():
	_trade(0, 1) # food, buy

func _on_food_sell():
	_trade(0, -1) # food, selling

func _on_food_amount_changed(new_amount):
	foodAmount.value = new_amount
	foodPrice.text = "Price: $" + str(int(1. / 1000.0 * building_control.food_price * foodAmount.value))


func _on_wood_buy():
	_trade(1, 1) # wood, buy

func _on_wood_sell():
	_trade(1, -1) # wood, selling

func _on_wood_amount_changed(new_amount):
	woodAmount.value = new_amount
	woodPrice.text = "Price: $" + str(int(1. / 1000.0 * building_control.wood_price * woodAmount.value))


func _on_stone_buy():
	_trade(2, 1) # stone, buy

func _on_stone_sell():
	_trade(2, -1) # stone, selling

func _on_stone_amount_changed(new_amount):
	stoneAmount.value = new_amount
	stonePrice.text = "Price: $" + str(int(1. / 1000.0 * building_control.stone_price * stoneAmount.value))


func _on_iron_buy():
	_trade(3, 1) # iron, buy

func _on_iron_sell():
	_trade(3, -1) # iron, selling

func _on_iron_amount_changed(new_amount):
	ironAmount.value = new_amount
	ironPrice.text = "Price: $" + str(int(1. / 1000.0 * building_control.iron_price * ironAmount.value))


func _on_ruby_buy():
	_trade(4, 1) # ruby, buy

func _on_ruby_sell():
	_trade(4, -1) # ruby, selling

func _on_ruby_amount_changed(new_amount):
	rubyAmount.value = new_amount
	rubyPrice.text = "Price: $" + str(int(1. / 1.0 * building_control.ruby_price * rubyAmount.value))


func _on_diamond_buy():
	_trade(5, 1) # diamond, buy

func _on_diamond_sell():
	_trade(5, -1) # diamond, selling

func _on_diamond_amount_changed(new_amount):
	diamondAmount.value = new_amount
	diamondPrice.text = "Price: $" + str(int(1. / 1.0 * building_control.diamond_price * diamondAmount.value))
