extends CutsceneEventBase
class_name LoadingScreenEvent

@export var Show : bool
@export var FadeTime : float = 1.5
@export var WaitForFade : bool = true

var delta = 0

func Enter(_context : CutsceneContext):
	delta = 0
	if Show:
		GameManager.ShowLoadingScreen(FadeTime)
	else:
		GameManager.HideLoadingScreen(FadeTime)
	return true

func Execute(_delta, _context : CutsceneContext):
	if WaitForFade:
		delta += _delta
		if delta > FadeTime:
			return true
		else:
			return false
	else:
		return true
