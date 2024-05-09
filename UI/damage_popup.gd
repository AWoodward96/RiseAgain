extends Node2D

@export var damage_val: Label

func SetValue(_val):
	damage_val.text = str("-", _val)
