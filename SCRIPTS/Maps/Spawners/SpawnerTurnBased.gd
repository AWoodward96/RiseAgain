extends SpawnerBasic
class_name SpawnerTurnBased

@export var TurnsToSpawn : Array[int]

func CanSpawn(_map : Map):
	if !Enabled:
		return false

	var myTile = _map.grid.GetTile(Position)
	if myTile == null || (myTile != null && myTile.Occupant != null):
		return false

	for i in TurnsToSpawn:
		if i == _map.turnCount:
			return true
	return false
