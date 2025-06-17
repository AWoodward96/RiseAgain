extends CutsceneEventBase
class_name ShowEventPrompt


const DELTA_MINIMUM = 0.25
@export var loc_text : String
@export var loc_madlib : MadLibLoc
@export var instantaneous : bool = false
@export var clearOnExit : bool = true


var blockClickThrough = false
var scrawlComplete = false

func Enter(_context : CutsceneContext):
	if loc_text != "":
		CutsceneManager.ShowEventPrompt(tr(loc_text), instantaneous)
	elif loc_madlib != null:
		var str = loc_madlib.GetString(_context)
		CutsceneManager.ShowEventPrompt(str, instantaneous)


	scrawlComplete = false
	CutsceneManager.EventPromptScrawlComplete.connect(OnScrawlComplete)
	blockClickThrough = true
	return true

func Execute(_delta : float, _context : CutsceneContext):
	if blockClickThrough:
		# Wait for select to be depressed
		if !InputManager.selectHeld && !InputManager.selectDown:
			blockClickThrough = false
		return false

	if InputManager.selectDown:
		if !scrawlComplete:
			CutsceneManager.ForceCompleteEventPromptScrawl()
			return false
		else:
			return true

	return false

func Exit(_context : CutsceneContext):
	if clearOnExit:
		CutsceneManager.HideEventPrompt()

	CutsceneManager.EventPromptScrawlComplete.disconnect(OnScrawlComplete)
	return true

func OnScrawlComplete():
	scrawlComplete = true
	pass
