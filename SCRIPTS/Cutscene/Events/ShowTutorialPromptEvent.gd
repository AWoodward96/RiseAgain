extends CutsceneEventBase
class_name ShowTutorialPromptEvent

@export var show : bool = true
@export var size : Vector2 = Vector2(280, 80)
@export var anchor : Control.LayoutPreset = Control.LayoutPreset.PRESET_BOTTOM_RIGHT
@export var loc_text : String
@export var builtInFreeze : bool = false
@export var freezeDuration : float = 0.0

var frozen : bool = false
var frozenTime : float = 0


func Enter(_context : CutsceneContext):
	#if Map.Current != null && Map.Current.playercontroller != null && Map.Current.playercontroller.combatHUD != null:
		#if show:
			#Map.Current.playercontroller.combatHUD.ShowTutorialPrompt(loc_text, anchor)
		#else:
			#Map.Current.playercontroller.combatHUD.HideTutorialPrompt()
		#return true

	if show:
		CutsceneManager.ShowGlobalTutorialPrompt(loc_text, anchor, size, builtInFreeze)
	else:
		CutsceneManager.HideGlobalTutorialPrompt()

	if builtInFreeze:
		frozen = true
		frozenTime = 0
		GameManager.get_tree().paused = true
	else:
		CutsceneManager.UpdateTutorialPromptWaitTime()
	return true

func Execute(_delta, _context : CutsceneContext):
	if !builtInFreeze:
		return true

	frozenTime += _delta

	CutsceneManager.UpdateTutorialPromptWaitTime(frozenTime, freezeDuration)
	if freezeDuration > 0:
		if frozenTime > freezeDuration:
			if Input.is_anything_pressed():
				frozen = false
			return !frozen
		else:
			return false
	else:
		if Input.is_anything_pressed():
			frozen = false
		return !frozen

func Exit(_context : CutsceneContext):
	GameManager.get_tree().paused = false
