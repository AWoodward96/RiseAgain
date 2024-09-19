extends Node2D

@export var damage_val: Label
@export var heal_val : Label
@export var armor_val : Label


func SetDamageValue(_val):
	TurnOffEverything()
	damage_val.text = str("-", _val)
	damage_val.visible = true

func SetHealValue(_val):
	TurnOffEverything()
	heal_val.text = str("+", _val)
	heal_val.visible = true

func SetArmorValue(_val):
	TurnOffEverything()
	armor_val.text = str("+", _val)
	armor_val.visible = true

func SetMiss():
	TurnOffEverything()
	damage_val.text = "Miss!!"
	damage_val.visible = true

func TurnOffEverything():
	damage_val.visible = false
	heal_val.visible = false
	armor_val.visible = false
