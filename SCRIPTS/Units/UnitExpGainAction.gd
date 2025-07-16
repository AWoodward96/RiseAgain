extends UnitActionBase
class_name UnitExpGainAction


var ExpGained : int
var waitForUI = true
var ExpUI : ExperienceGainUI

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	if _unit.UnitAllegiance != GameSettingsTemplate.TeamID.ALLY:
		waitForUI = false
		return

	waitForUI = true
	ExpUI = ExperienceGainUI.Show(ExpGained, _unit, map, map.mapRNG)
	ExpUI.SequenceComplete.connect(OnSequenceComplete)

	pass

func _Execute(_unit : UnitInstance, _delta):
	return !waitForUI

func OnSequenceComplete():
	if ExpUI != null:
		ExpUI.SequenceComplete.disconnect(OnSequenceComplete)
		ExpUI = null

	waitForUI = false
