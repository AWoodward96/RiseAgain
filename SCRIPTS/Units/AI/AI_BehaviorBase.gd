extends Resource
class_name AIBehaviorBase

var map : Map
var unit : UnitInstance

var grid : Grid
var pathfinding  : AStarGrid2D

func StartTurn(_map : Map, _unit : UnitInstance):
	unit = _unit
	map = _map
	grid = map.grid
	pathfinding = grid.Pathfinding

	unit.QueueTurnStartDelay()
	pass

func RunTurn():
	pass
