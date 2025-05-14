extends ActionStep
class_name SummonStep

@export var UseActionOrigin : bool = true

@export var UnitToSummon : UnitTemplate
@export var AI : AIBehaviorBase
@export var AggroBehavior : AlwaysAggro



func Enter(_actionLog : ActionLog):
	super(_actionLog)

	if UseActionOrigin:
		SummonOnTile(_actionLog.actionOriginTile)
	else:
		for targetedTile in _actionLog.affectedTiles:
			SummonOnTile(targetedTile.Tile)
	pass


func SummonOnTile(_tile : Tile):
	if _tile == null:
		push_error("Ability: " + log.ability.internalName + " attempted to spawn a unit on a null tile. Map: " + "Map: " + Map.Current.name)
		return

	var map = Map.Current
	var unit = map.CreateUnit(UnitToSummon, log.source.Level)
	map.InitializeUnit(unit, _tile.Position, log.source.UnitAllegiance)
	unit.SetAI(AI, AggroBehavior)

	# End the zombified Unit's turn so that it doesn't mess up the turn order
	unit.EndTurn()
