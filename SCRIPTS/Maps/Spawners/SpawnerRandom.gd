@tool
extends SpawnerBase
class_name SpawnerRandom

@export var UnitOptions : Array[UnitTemplate]
@export var playerRosterDuplicateProtection : bool = false
@export var UnitLevel : int = 0 # remember, this is indexed

func SpawnEnemy(_map : Map, _rng : DeterministicRNG):
	if UnitTemplate == null || !Enabled:
		return

	var selectedUnit : UnitTemplate

	if playerRosterDuplicateProtection:
		var infiniteProtection = 0
		var currentCampaign = GameManager.CurrentCampaign
		if currentCampaign == null:
			var rand = _rng.NextInt(0, UnitOptions.size() - 1)
			selectedUnit = UnitOptions[rand]
		else:
			var rand : int
			while infiniteProtection < 100:
				rand = _rng.NextInt(0, UnitOptions.size() - 1)
				var valid = true
				for u in currentCampaign.CurrentRoster:
					if u.Template == UnitOptions[rand]:
						valid = false
						break

				infiniteProtection += 1
				if valid:
					break

			selectedUnit = UnitOptions[rand]
	else:
		var rand = _rng.NextInt(0, UnitOptions.size() - 1)
		selectedUnit = UnitOptions[rand]

	var unit = _map.CreateUnit(selectedUnit, UnitLevel)
	_map.InitializeUnit(unit, Position, Allegiance)
	unit.SetAI(AIBehavior, AggroBehavior)

	if _map.CurrentCampaign != null && Allegiance == GameSettingsTemplate.TeamID.ALLY:
		_map.CurrentCampaign.CurrentRoster.append(unit)

	unit.IsBoss = Boss
