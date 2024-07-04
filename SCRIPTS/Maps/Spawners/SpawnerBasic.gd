@tool
extends SpawnerBase

@export var UnitToSpawn : UnitTemplate :
	set(value):
		UnitToSpawn = value
		if value != null:
			name = PREFIX + UnitToSpawn.DebugName

@export var UnitLevel : int = 0 # remember, this is indexed

func SpawnEnemy(_map : Map, _rng : RandomNumberGenerator):
	if UnitTemplate == null || !Enabled:
		return

	var unit = _map.CreateUnit(UnitToSpawn, UnitLevel)
	_map.InitializeUnit(unit, Position, Allegiance)
	unit.SetAI(AIBehavior, AggroBehavior)

	if _map.CurrentCampaign != null && Allegiance == GameSettingsTemplate.TeamID.ALLY:
		_map.CurrentCampaign.CurrentRoster.append(unit)
