extends CutsceneEventBase
class_name SubCutsceneEventBlock


@export var Cutscene : CutsceneTemplate

func Enter(_context : CutsceneContext):
	if Cutscene == null:
		return false

	return Cutscene.CanStart(_context)

func Execute(_delta : float, _context : CutsceneContext):
	if Cutscene == null:
		# If we somehow get here (we shouldn't) just break out so nothing freezes
		return true

	return Cutscene.Execute(_delta, _context)
