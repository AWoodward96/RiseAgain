@tool
extends SpawnerBase
class_name SpawnerBasic

@export var UnitToSpawn : UnitTemplate :
	set(value):
		UnitToSpawn = value
		UpdateName()

@export var UnitLevel : int = 0 # remember, this is indexed
@export var DeltaLevel : int = -1 # The level of this unit relative to the highest level of the campaign. Defaulting to -1, because otherwise the exp gain on a unit that level would be too snowbally
@export var ExtraEXPGranted : int = 0
@export var PreAppliedEffects : Array[CombatEffectTemplate]

func UpdateName():
	if UnitToSpawn == null:
		name = "Empty_Spawner"
	else:
		var newName = ""
		if !Enabled:
			newName += "DISABLED_"

		newName += PREFIX + UnitToSpawn.DebugName
		name = newName

func OnEnableToggled():
	UpdateName()

func SpawnEnemy(_map : Map, _rng : DeterministicRNG):
	if UnitTemplate == null || !Enabled:
		return

	var level = UnitLevel
	if _map.CurrentCampaign != null:
		# Go with whichever one is higher at the moment
		level = max(_map.CurrentCampaign.currentLevelDifficulty, UnitLevel)

	# No negative levels plz
	level = max(level, 0)

	var unit = _map.CreateUnit(UnitToSpawn, level + DeltaLevel)
	_map.InitializeUnit(unit, Position, Allegiance, 1, ExtraHealthBars)
	unit.SetAI(AIBehavior, AggroBehavior)
	unit.ExtraEXPGranted = ExtraEXPGranted

	for itemPath in GivenItems:
		var loadedItem = load(itemPath) as PackedScene
		if loadedItem != null:
			unit.TryEquipItem(loadedItem)
		pass

	for effect in PreAppliedEffects:
		var instance = effect.CreateInstance(unit, unit, null, null)
		unit.AddCombatEffect(instance)
	if _map.CurrentCampaign != null && Allegiance == GameSettingsTemplate.TeamID.ALLY:
		_map.CurrentCampaign.CurrentRoster.append(unit)


	unit.IsBoss = Boss
	unit.RefreshVisuals()
