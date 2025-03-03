extends CutsceneEventBase
class_name BlockSaveEvent

@export var BlockUniverseSave : bool
@export var BlockCampaignSave : bool
@export var BlockMapSave : bool

func Enter(_context : CutsceneContext):
	PersistDataManager.BlockCampaignSave = BlockCampaignSave
	PersistDataManager.BlockMapSave = BlockMapSave
	PersistDataManager.BlockUniverseSave = BlockUniverseSave
	return true
