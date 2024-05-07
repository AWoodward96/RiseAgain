@tool
extends SpawnerBase

@export var UnitTemplate : UnitTemplate :
	set(value):
		UnitTemplate = value
		name = PREFIX + UnitTemplate.DebugName

func SpawnEnemy(_map : Map, _rng : RandomNumberGenerator):
	if UnitTemplate == null || !Enabled:
		return

	var unit = _map.InitializeUnit(UnitTemplate, Position, Allegiance)
	unit.SetAI(AIBehavior)
