extends Node2D
class_name PassiveListenerBase

var ability : Ability
var map : Map

func RegisterListener(_ability : Ability, _map : Map):
	map = _map
	ability = _ability
	pass
