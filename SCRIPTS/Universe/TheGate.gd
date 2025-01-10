extends TopdownInteractable
class_name Gate

@export var UIParent : Node
@export var RouteEntryParent : EntryList
@export var RouteEntryPrefab : PackedScene
@export var LoadoutEntryParent : EntryList
@export var LoadoutEntryPrefab : PackedScene

var hasInteractable : bool
var availableCampaigns : Array[CampaignTemplate]


func _ready() -> void:
	super()
	UIParent.visible = false

# This is where the Player goes and sets off on a mission
func OnInteract():
	super()
	TopDownPlayer.BlockInputCounter += 1
	SetInteractable(true)
	pass

func SetInteractable(_bool : bool):
	UIParent.visible = _bool
	hasInteractable = true
	if _bool:
		UpdateUI()

func _process(_delta: float) -> void:
	if InputManager.cancelDown && hasInteractable:
		TopDownPlayer.BlockInputCounter -= 1
		SetInteractable(false)

func UpdateUI():
	GatherCampaigns()

	RouteEntryParent.ClearEntries()
	for campaignTemplate in availableCampaigns:
		var entry = RouteEntryParent.CreateEntry(RouteEntryPrefab)
		entry.Initialize(self, campaignTemplate)

	RouteEntryParent.FocusFirst()
	RefreshLoadout()
	pass

func RefreshLoadout():
	LoadoutEntryParent.ClearEntries()
	var loadout = PersistDataManager.universeData.bastionData.SelectedRoster
	for unit in loadout:
		var textRect = LoadoutEntryParent.CreateEntry(LoadoutEntryPrefab)
		textRect.texture = unit.icon

func GatherCampaigns():
	availableCampaigns.clear()
	for packedScene in GameManager.GameSettings.CampaignManifest:
		var template = packedScene.instantiate() as CampaignTemplate
		if template != null:
			availableCampaigns.append(template)

func CampaignSelected(_campaignTemplate : CampaignTemplate):
	GameManager.StartCampaign(CampaignInitData.Construct(_campaignTemplate, PersistDataManager.universeData.bastionData.SelectedRoster))
	pass

func OnShutdown():
	UIParent.visible = false
