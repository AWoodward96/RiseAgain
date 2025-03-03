extends CutsceneEventBase
class_name WaitForTurnStartEvent

@export var TeamID : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY

var passReq = false

func Enter(_context : CutsceneContext):
	if Map.Current == null:
		return false

	passReq = false
	Map.Current.OnTurnStart.connect(TurnStart)
	return true

func Execute(_delta, _context : CutsceneContext):
	return passReq

func TurnStart(_teamTurnID : GameSettingsTemplate.TeamID):
	if TeamID == _teamTurnID:
		passReq = true
