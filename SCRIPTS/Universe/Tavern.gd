extends TopdownInteractable
class_name Tavern


# This is where the Player goes and sets off on a mission

@export var UIParent : Node
@export var Anim : AnimationPlayer
@export var CharacterEntryParent : EntryList
@export var CharacterEntryPrefab : PackedScene
@export var LoadoutEntryParent : EntryList
@export var LoadoutEntryPrefab : PackedScene


var hasInteractable : bool

func _ready() -> void:
	super()
	UIParent.visible = false


func OnInteract():
	super()
	TopDownPlayer.BlockInputCounter += 1
	SetInteractable(true)
	pass

func SetInteractable(_bool : bool):
	UIParent.visible = _bool
	hasInteractable = true
	if _bool:
		Anim.play("Show")
		InitializeUI()

func InitializeUI():
	CharacterEntryParent.ClearEntries()
	var unitsInTavern = PersistDataManager.universeData.bastionData.UnitsInTavern
	var unitsInCampsite = PersistDataManager.universeData.bastionData.UnitsInCampsite
	for u in unitsInTavern:
		var entry = CharacterEntryParent.CreateEntry(CharacterEntryPrefab)
		entry.Initialize(u, self)

	for u in unitsInCampsite:
		var entry = CharacterEntryParent.CreateEntry(CharacterEntryPrefab)
		entry.Initialize(u, self)

	CharacterEntryParent.FocusFirst()
	RefreshLoadout()

func RefreshLoadout():
	LoadoutEntryParent.ClearEntries()
	var loadout = PersistDataManager.universeData.bastionData.SelectedRoster
	for unit in loadout:
		var textRect = LoadoutEntryParent.CreateEntry(LoadoutEntryPrefab)
		textRect.texture = unit.icon

func _process(_delta: float) -> void:
	if InputManager.cancelDown && hasInteractable:
		TopDownPlayer.BlockInputCounter -= 1
		SetInteractable(false)
