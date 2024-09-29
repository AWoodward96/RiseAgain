extends UnitActionBase
class_name UnitExpGainAction


var ExpGained : int
var waitForUI = true

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	if _unit.UnitAllegiance != GameSettingsTemplate.TeamID.ALLY:
		waitForUI = false
		return

	waitForUI = true
	var expUI = ExperienceGainUI.Show(ExpGained, _unit, map, map.rng)
	expUI.SequenceComplete.connect(OnSequenceComplete)

	pass

func _Execute(_unit : UnitInstance, _delta):
	return !waitForUI

func OnSequenceComplete():
	waitForUI = false
