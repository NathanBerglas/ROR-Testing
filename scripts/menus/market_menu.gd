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

const price_volatility = 20.0
const spread_volatility = 15.0

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
	treasure_label.text = "Treasury Amount: $" + str(building_control.money).pad_decimals(0)
	
	foodLabel.text = "Food: " + str(building_control.food)
	foodPricePerUnit.text = "Buy 1k: $" + str(building_control.food_price + building_control.food_spread / 2).pad_decimals(0) + ", Sell 1k: $" + str(building_control.food_price - building_control.food_spread / 2).pad_decimals(0)
	
	woodLabel.text = "Wood: " + str(building_control.wood)
	woodPricePerUnit.text = "Buy 1k: $" + str(building_control.wood_price + building_control.wood_spread / 2).pad_decimals(0) + ", Sell 1k: $" + str(building_control.wood_price - building_control.wood_spread / 2).pad_decimals(0)
	
	stoneLabel.text = "Stone: " + str(building_control.stone)
	stonePricePerUnit.text = "Buy 1k: $" + str(building_control.stone_price + building_control.stone_spread / 2).pad_decimals(0) + ", Sell 1k: $" + str(building_control.stone_price - building_control.stone_spread / 2).pad_decimals(0)
	
	ironLabel.text = "Iron: " + str(building_control.iron)
	ironPricePerUnit.text = "Buy 1k: $" + str(building_control.iron_price + building_control.iron_spread / 2).pad_decimals(0) + ", Sell 1k: $" + str(building_control.iron_price - building_control.iron_spread / 2).pad_decimals(0)
	
	rubyLabel.text = "Ruby: " + str(building_control.ruby)
	rubyPricePerUnit.text = "Buy 1: $" + str(building_control.ruby_price + building_control.ruby_spread / 2).pad_decimals(0) + ", Sell 1: $" + str(building_control.ruby_price - building_control.ruby_spread / 2).pad_decimals(0)
	
	diamondLabel.text = "Diamond: " + str(building_control.diamond)
	diamondPricePerUnit.text = "Buy 1: $" + str(building_control.diamond_price + building_control.diamond_spread / 2).pad_decimals(0) + ", Sell 1: $" + str(building_control.diamond_price - building_control.diamond_spread / 2).pad_decimals(0)


func _trade(resource_id, is_buying):
	var amount_value = 0
	var buy_price = 1
	var sell_price = 1
	var units_in_inventory = 0
	var price_per_X: float = 1.0 # Must also be set in _on_resource_amount_changed
	if resource_id == 0: # diamond
		amount_value = foodAmount.value
		buy_price = building_control.food_price + building_control.food_spread / 2
		sell_price = building_control.food_price - building_control.food_spread / 2
		units_in_inventory = building_control.food
		price_per_X = 1000.0
	elif resource_id == 1: # wood
		amount_value = woodAmount.value
		buy_price = building_control.wood_price + building_control.wood_spread / 2
		sell_price = building_control.wood_price - building_control.wood_spread / 2
		units_in_inventory = building_control.wood
		price_per_X = 1000.0
	elif resource_id == 2: # stone
		amount_value = stoneAmount.value
		buy_price = building_control.stone_price + building_control.stone_spread / 2
		sell_price = building_control.stone_price + building_control.stone_spread / 2
		units_in_inventory = building_control.stone
		price_per_X = 1000.0
	elif resource_id == 3: # iron
		amount_value = ironAmount.value
		buy_price = building_control.iron_price + building_control.iron_spread / 2
		sell_price = building_control.iron_price - building_control.iron_spread / 2
		units_in_inventory = building_control.iron
		price_per_X = 1000.0
	elif resource_id == 4: # ruby
		amount_value = rubyAmount.value
		buy_price = building_control.ruby_price + building_control.ruby_spread / 2
		sell_price = building_control.ruby_price - building_control.ruby_spread / 2
		units_in_inventory = building_control.ruby
		price_per_X = 1.0
	elif resource_id == 5: # diamond
		amount_value = diamondAmount.value
		buy_price = building_control.diamond_price + building_control.diamond_spread / 2
		sell_price = building_control.diamond_price - building_control.diamond_spread / 2
		units_in_inventory = building_control.diamond
		price_per_X = 1.0
		
	var trade_quantity = 0
	if is_buying == 1: # Buying
		trade_quantity = clamp(amount_value, 0, int(price_per_X * building_control.money / buy_price)) # What they can afford
		building_control.money -= int(ceil(1. / price_per_X * buy_price * trade_quantity))
	elif is_buying == -1: # Selling
		trade_quantity = clamp(amount_value, 0, units_in_inventory) # What they can afford
		building_control.money += int(1. / price_per_X * sell_price * trade_quantity)
		
	if resource_id == 0: #food
		building_control.food += int(trade_quantity) * is_buying
		building_control.food_global_inventory -= int(trade_quantity) * is_buying
		var imbalance = (building_control.food_baseline - building_control.food_global_inventory) / building_control.food_baseline
		building_control.food_price = building_control.food_price_baseline * exp(price_volatility * imbalance)
		building_control.food_spread = building_control.food_spread_baseline * (1 + spread_volatility * abs(imbalance))
		_on_food_amount_changed(0)
	elif resource_id == 1: #wood
		building_control.wood += int(trade_quantity) * is_buying
		building_control.wood_global_inventory -= int(trade_quantity) * is_buying
		var imbalance = (building_control.wood_baseline - building_control.wood_global_inventory) / building_control.wood_baseline
		building_control.wood_price = building_control.wood_price_baseline * exp(price_volatility * imbalance)
		building_control.wood_spread = building_control.wood_spread_baseline * (1 + spread_volatility * abs(imbalance))
		_on_wood_amount_changed(0)
	elif resource_id == 2: #stone
		building_control.stone += int(trade_quantity) * is_buying
		building_control.stone_global_inventory -= int(trade_quantity) * is_buying
		var imbalance = (building_control.stone_baseline - building_control.stone_global_inventory) / building_control.stone_baseline
		building_control.stone_price = building_control.stone_price_baseline * exp(price_volatility * imbalance)
		building_control.stone_spread = building_control.stone_spread_baseline * (1 + spread_volatility * abs(imbalance))
		_on_stone_amount_changed(0)
	elif resource_id == 3: #iron
		building_control.iron += int(trade_quantity) * is_buying
		building_control.iron_global_inventory -= int(trade_quantity) * is_buying
		var imbalance = (building_control.iron_baseline - building_control.iron_global_inventory) / building_control.iron_baseline
		building_control.iron_price = building_control.iron_price_baseline * exp(price_volatility * imbalance)
		building_control.iron_spread = building_control.iron_spread_baseline * (1 + spread_volatility * abs(imbalance))
		_on_iron_amount_changed(0)
	elif resource_id == 4: #ruby
		building_control.ruby += int(trade_quantity) * is_buying
		building_control.ruby_global_inventory -= int(trade_quantity) * is_buying
		var imbalance = (building_control.ruby_baseline - building_control.ruby_global_inventory) / building_control.ruby_baseline
		building_control.ruby_price = building_control.ruby_price_baseline * exp(price_volatility * imbalance)
		building_control.ruby_spread = building_control.ruby_spread_baseline * (1 + spread_volatility * abs(imbalance))
		_on_ruby_amount_changed(0)
	elif resource_id == 5: #diamond
		building_control.diamond += int(trade_quantity) * is_buying
		building_control.diamond_global_inventory  -= int(trade_quantity) * is_buying
		var imbalance = (building_control.diamond_baseline - building_control.diamond_global_inventory) / building_control.diamond_baseline
		building_control.diamond_price = building_control.diamond_price_baseline * exp(price_volatility * imbalance)
		building_control.diamond_spread = building_control.diamond_spread_baseline * (1 + spread_volatility * abs(imbalance))
		_on_diamond_amount_changed(0)
	
	update_ui()
	return


func _amount_changed(new_amount, buy_price, sell_price, units_in_inventory, price_per_X):
	var text = "Price: $" + str(ceil(1. / price_per_X * buy_price * new_amount)).pad_decimals(0) + " / $" + str(int(1. / price_per_X * sell_price * new_amount)).pad_decimals(0)
	var buy_disabled = false
	var sell_disabled = false
	if new_amount > int(price_per_X * building_control.money / buy_price) or new_amount == 0:
		buy_disabled = true
	if new_amount > units_in_inventory or new_amount == 0:
		sell_disabled = true
	return {"text": text, "buy_disabled": buy_disabled, "sell_disabled": sell_disabled}


func _on_food_buy():
	_trade(0, 1) # food, buy

func _on_food_sell():
	_trade(0, -1) # food, selling

func _on_food_amount_changed(new_amount):
	var output = _amount_changed(new_amount, 
	building_control.food_price + building_control.food_spread / 2,
	building_control.food_price - building_control.food_spread / 2,
	building_control.food, 1000.0)
	foodAmount.value = new_amount
	foodPrice.text = output["text"]
	foodBuyButton.disabled = output["buy_disabled"]
	foodSellButton.disabled = output["sell_disabled"]

func _on_wood_buy():
	_trade(1, 1) # wood, buy

func _on_wood_sell():
	_trade(1, -1) # wood, selling

func _on_wood_amount_changed(new_amount):
	var output = _amount_changed(new_amount, 
	building_control.wood_price + building_control.wood_spread / 2,
	building_control.wood_price - building_control.wood_spread / 2,
	building_control.wood, 1000.0)
	woodAmount.value = new_amount
	woodPrice.text = output["text"]
	woodBuyButton.disabled = output["buy_disabled"]
	woodSellButton.disabled = output["sell_disabled"]

func _on_stone_buy():
	_trade(2, 1) # stone, buy

func _on_stone_sell():
	_trade(2, -1) # stone, selling

func _on_stone_amount_changed(new_amount):
	var output = _amount_changed(new_amount, building_control.stone_price + building_control.stone_spread / 2, building_control.stone_price - building_control.stone_spread / 2, building_control.stone, 1000.0)
	stoneAmount.value = new_amount
	stonePrice.text = output["text"]
	stoneBuyButton.disabled = output["buy_disabled"]
	stoneSellButton.disabled = output["sell_disabled"]


func _on_iron_buy():
	_trade(3, 1) # iron, buy

func _on_iron_sell():
	_trade(3, -1) # iron, selling

func _on_iron_amount_changed(new_amount):
	var output = _amount_changed(new_amount, 
	building_control.iron_price + building_control.iron_spread / 2,
	building_control.iron_price - building_control.iron_spread / 2,
	building_control.iron, 1000.0)
	ironAmount.value = new_amount
	ironPrice.text = output["text"]
	ironBuyButton.disabled = output["buy_disabled"]
	ironSellButton.disabled = output["sell_disabled"]


func _on_ruby_buy():
	_trade(4, 1) # ruby, buy

func _on_ruby_sell():
	_trade(4, -1) # ruby, selling

func _on_ruby_amount_changed(new_amount):
	var output = _amount_changed(new_amount, 
	building_control.ruby_price + building_control.ruby_spread / 2,
	building_control.ruby_price - building_control.ruby_spread / 2,
	building_control.ruby, 1.0)
	rubyAmount.value = new_amount
	rubyPrice.text = output["text"]
	rubyBuyButton.disabled = output["buy_disabled"]
	rubySellButton.disabled = output["sell_disabled"]
	

func _on_diamond_buy():
	_trade(5, 1) # diamond, buy

func _on_diamond_sell():
	_trade(5, -1) # diamond, selling

func _on_diamond_amount_changed(new_amount):
	var output = _amount_changed(new_amount, 
	building_control.diamond_price + building_control.diamond_spread / 2,
	building_control.diamond_price - building_control.diamond_spread / 2,
	building_control.diamond, 1.0)
	diamondAmount.value = new_amount
	diamondPrice.text = output["text"]
	diamondBuyButton.disabled = output["buy_disabled"]
	diamondSellButton.disabled = output["sell_disabled"]
