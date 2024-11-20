class_name TileTargetedData

var Tile : Tile
var AOEMultiplier : float = 1
var CritModifier : float = 0
var AccuracyModifier : float = 0

# This is for pushing or pulling the target -- not for self movement
var pushDirection : GameSettingsTemplate.Direction
var pushAmount : int = 0
var willPush : bool :
	get:
		return pushAmount > 0

var carryLimit : int = 2
var pushStack : Array[PushResult]
var pushCollision : Tile			# If not null - this is the Tile that ended up stopping the push
var pushCanDamageUser : bool
