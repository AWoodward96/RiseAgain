@tool
extends SpawnerBase
class_name SpawnerRandom

@export var UnitOptions : Array[UnitTemplate]

@export var UnitLevel : int = 0 # remember, this is indexed

func SpawnEnemy(_map : Map, _rng : RandomNumberGenerator):
	if UnitTemplate == null || !Enabled:
		return

	var rand = _rng.randi_range(0, UnitOptions.size() - 1)

	var unit = _map.CreateUnit(UnitOptions[rand], UnitLevel)
	_map.InitializeUnit(unit, Position, Allegiance)
	unit.SetAI(AIBehavior, AggroBehavior)

	if _map.CurrentCampaign != null && Allegiance == GameSettingsTemplate.TeamID.ALLY:
		_map.CurrentCampaign.CurrentRoster.append(unit)
