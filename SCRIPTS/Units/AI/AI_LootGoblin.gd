extends AISmartTarget
class_name AILootGoblin

@export var tileToLoot : Array[Vector2i]
@export var tryToEscape : bool
@export var escapeRoute : Vector2i

var isEscaping : bool = false
var selectedTarget : GEChest


func StartTurn(_map : Map, _unit : UnitInstance):
	CommonStartTurn(_map, _unit)

	# Check if there are any tiles left to loot.
	# if there aren't, try to escape
	var foundTileToLoot = false
	var allTilesLooted = true
	for coord in tileToLoot:
		if foundTileToLoot:
			break

		var tile = map.grid.GetTile(coord)
		if tile != null:
			for ge in tile.GridEntities:
				if ge is GEChest:
					if !ge.claimed:
						allTilesLooted = false
						foundTileToLoot = true
						var option = EnemyAIOption.Construct(_unit, null, map, null)
						if _unit.CurrentTile != tile:
							option.roughPath = map.grid.GetTilePath(_unit, _unit.CurrentTile, tile, true, true)
							option.TruncatePathToMovement(option.roughPath)
							selectedOption = option
							selectedTarget = ge

						break


	if !foundTileToLoot:
		if allTilesLooted && tryToEscape:
			var escapeTile = map.grid.GetTile(escapeRoute)
			if _unit.CurrentTile == escapeTile:
				map.RemoveUnitFromMap(unit, false)
			else:
				var escapeOption = EnemyAIOption.Construct(_unit, null, map, null)
				escapeOption.roughPath = map.grid.GetTilePath(_unit, _unit.CurrentTile, escapeTile, true, true)
				escapeOption.TruncatePathToMovement(escapeOption.roughPath)
				selectedOption = escapeOption
				unit.MoveCharacterToNode(escapeOption.path, escapeOption.tileToMoveTo)
				unit.QueueEndTurn()
		else:
			super(_map, _unit)
	else:
		unit.MoveCharacterToNode(selectedOption.path, selectedOption.tileToMoveTo)



func RunTurn():
	if unit.IsStackFree && unit.Activated:
		if unit.CurrentTile == selectedTarget.Origin:
			selectedTarget.Claim(unit)
			unit.QueueEndTurn()
		elif !attacked:
			TryCombat()

	pass
