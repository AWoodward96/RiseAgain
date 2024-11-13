extends ActionStep
class_name SummonStep


func Enter(_actionLog : ActionLog):
	super(_actionLog)

	var component = ability.SummonData
	if component != null:
		if component.UseActionOrigin:
			SummonOnTile(_actionLog.actionOriginTile, component)
		else:
			for targetedTile in _actionLog.affectedTiles:
				SummonOnTile(targetedTile.Tile, component)
	pass


func SummonOnTile(_tile : Tile, _comp : SummonUnitComponent):
	if _tile == null || _comp == null:
		push_error("Ability: " + log.ability.internalName + " attempted to spawn a unit on a null tile or with a null summon unit component. Map: " + "Map: " + Map.Current.name)
		return

	var map = Map.Current
	var unit = map.CreateUnit(_comp.UnitToSummon, log.source.Level)
	map.InitializeUnit(unit, _tile.Position, log.source.UnitAllegiance)
	unit.SetAI(_comp.AI, _comp.AggroBehavior)

	# End the zombified Unit's turn so that it doesn't mess up the turn order
	unit.EndTurn()
