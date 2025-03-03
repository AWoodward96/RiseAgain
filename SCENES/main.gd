extends Node2D
class_name Main

static var Root : Main

@export var DEBUG_Campaign : CampaignTemplate
@export var DEBUG_ShowcaseMode : bool

@export var BastionParent : Node2D
@export var CampaignParent : Node2D

@export var Debug_Cutscene : CutsceneTemplate


var currentBastion : Bastion

func _ready():
	Root = self

	if DEBUG_Campaign != null && DEBUG_ShowcaseMode && GameManager.CurrentCampaign == null:
		#GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(_campaignTemplate, PersistDataManager.universeData.bastionData.SelectedRoster))
		GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(DEBUG_Campaign, []))

	if Debug_Cutscene != null:
		CutsceneManager.QueueCutscene(Debug_Cutscene)
