class_name Tile

var GlobalPosition
var Position
var IsWall

var CanAttack: bool
var CanMove: bool
var InRange : bool
var Occupant : UnitInstance

func AsTargetData():
	var target = TileTargetedData.new()
	target.Tile = self
	return target
