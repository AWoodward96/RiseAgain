class_name TileTargetedData

var Tile : Tile
var AOEMultiplier : float = 1

var moveDirection : GameSettingsTemplate.Direction
var moveAmount : int = 0
var shouldMove : bool :
	get:
		return moveAmount > 0
