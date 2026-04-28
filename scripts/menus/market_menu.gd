extends Control

@onready var building_control = self.get_parent().get_parent()
@onready var close_button = $Background/Close
@onready var treasure_label = $Background/Market/Treasury/TreasuryLabel

# Essentials


func _ready():
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed():
	visible = false
	building_control.hud.visible = true


func open():
	visible = true
	update_ui()


func update_ui():
	treasure_label.text = "Treasury Amount: $" + str(building_control.money)
