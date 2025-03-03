extends Resource
class_name CutsceneEventBase


func Enter(_context : CutsceneContext):
	return true

func Exit(_context : CutsceneContext):
	return true

func Execute(_delta : float, _context : CutsceneContext):
	return true
