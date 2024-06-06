extends Node2D

@export var damage_val: Label
@export var heal_val : Label


func SetDamageValue(_val):
	damage_val.text = str("-", _val)
	damage_val.visible = true
	heal_val.visible = false

func SetHealValue(_val):
	heal_val.text = str("+", _val)
	damage_val.visible = false
	heal_val.visible = true

func SetMiss():
	damage_val.text = "Miss!!"
	damage_val.visible = true
	heal_val.visible = false
