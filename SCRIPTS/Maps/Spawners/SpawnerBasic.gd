@tool
extends SpawnerBase

@export var UnitToSpawn : UnitTemplate :
	set(value):
		UnitToSpawn = value
		if value != null:
			name = PREFIX + UnitToSpawn.DebugName

func SpawnEnemy(_map : Map, _rng : RandomNumberGenerator):
	if UnitTemplate == null || !Enabled:
		return

	var unit = _map.CreateUnit(UnitToSpawn)
	_map.InitializeUnit(unit, Position, Allegiance)
	unit.SetAI(AIBehavior, AggroBehavior)
