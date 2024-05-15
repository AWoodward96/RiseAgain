class_name MapStateBase

var map : Map
var controller : PlayerController

func Enter(_map : Map, _ctrl : PlayerController):
	map = _map
	controller = _ctrl
	pass

func Exit():
	pass

func Update(_delta):
	pass
