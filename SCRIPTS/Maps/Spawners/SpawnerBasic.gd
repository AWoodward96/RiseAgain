@tool
extends SpawnerBase

@export var UnitToSpawn : UnitTemplate :
	set(value):
		UnitToSpawn = value
		if value != null:
			name = PREFIX + UnitToSpawn.DebugName

@export var UnitLevel : int = 0 # remember, this is indexed - NOT USED ANYMORE
@export var DeltaLevel : int = -1 # The level of this unit relative to the highest level of the campaign. Defaulting to -1, because otherwise the exp gain on a unit that level would be too snowbally
@export var PreAppliedEffects : Array[CombatEffectTemplate]

func SpawnEnemy(_map : Map, _rng : DeterministicRNG):
	if UnitTemplate == null || !Enabled:
		return

	var level = UnitLevel
	if _map.CurrentCampaign != null:
		# Go with whichever one is higher at the moment
		level = max(_map.CurrentCampaign.currentLevelDifficulty, UnitLevel)

	var unit = _map.CreateUnit(UnitToSpawn, level + DeltaLevel)
	_map.InitializeUnit(unit, Position, Allegiance)
	unit.SetAI(AIBehavior, AggroBehavior)

	for effect in PreAppliedEffects:
		var instance = effect.CreateInstance(unit, unit, null)
		unit.AddCombatEffect(instance)
	if _map.CurrentCampaign != null && Allegiance == GameSettingsTemplate.TeamID.ALLY:
		_map.CurrentCampaign.CurrentRoster.append(unit)
