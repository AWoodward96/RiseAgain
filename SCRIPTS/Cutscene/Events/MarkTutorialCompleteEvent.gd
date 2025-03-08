extends CutsceneEventBase
class_name MarkThisTutorialCompleteEvent

func Enter(_cutscene : CutsceneContext):
	PersistDataManager.universeData.completedCutscenes.append(_cutscene.Template)
	PersistDataManager.universeData.Save()
	return true
