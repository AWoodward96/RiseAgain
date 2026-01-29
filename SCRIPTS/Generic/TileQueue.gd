extends Object
class_name TileQueue

var tile : Tile
var weight : int

static func Construct(_tile : Tile, _weight : int):
	var new = TileQueue.new()
	new.tile = _tile
	new.weight = _weight
	return new
