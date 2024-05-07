@tool
extends SpawnerBase

@export var UnitToSpawn : UnitTemplate :
	set(value):
		UnitToSpawn = value
		name = PREFIX + UnitToSpawn.DebugName

func SpawnEnemy(_map : Map, _rng : RandomNumberGenerator):
	if UnitTemplate == null || !Enabled:
		return

	var unit = _map.InitializeUnit(UnitToSpawn, Position, Allegiance)
	unit.SetAI(AIBehavior)
