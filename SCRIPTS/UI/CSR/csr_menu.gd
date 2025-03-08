extends CanvasLayer
class_name CSR

static var Open : bool = false
static var AllAbilitiesCost0 : bool = false
static var AlwaysCrit : bool = false
static var NeverHit : bool = false
static var AutoWin : bool = false
static var AutoLose : bool = false
static var BlockRetaliation : bool = false

@export var FirstEntry : Control
@export var SpecificItem : PackedScene
@export var SpecificItem2 : PackedScene

func _ready():
	if FirstEntry != null:
		FirstEntry.grab_focus()

func btnAllAbilitiesCost0():
	AllAbilitiesCost0 = !AllAbilitiesCost0

func btnAlwaysCrit():
	AlwaysCrit = !AlwaysCrit

func btnNeverHit():
	NeverHit = !NeverHit

func btnUnlockAllAbilities():
	var map = Map.Current
	if map == null:
		return

	var allAllies = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	for unit in allAllies:
		if unit == null:
			continue

		var template = unit.Template as UnitTemplate
		if template == null:
			continue

		for abilityPath in template.Tier1Abilities:
			unit.AddAbility(load(abilityPath))
	pass

func btnGiveSpecificItem():
	var map = Map.Current
	if map == null:
		return

	var allAllies = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	for unit in allAllies:
		if unit == null:
			continue

		var template = unit.Template as UnitTemplate
		if template == null:
			continue

		unit.EquipItem(0, SpecificItem)
		unit.EquipItem(1, SpecificItem2)
	pass

func btnAutoWin():
	AutoWin = !AutoLose

func btnBlockRetaliation():
	BlockRetaliation = !BlockRetaliation

func btnSaveMap():
	PersistDataManager.SaveMap()

func TestAbilitySelectionScreen():
	var unit = GetCurrentHighlighedUnit() as UnitInstance
	if unit != null:
		SelectAbilityUI.Show(unit, unit.Template.Tier1Abilities)
		pass

static func ShowMenu():
	var csrMenu = UIManager.CSRUI.instantiate() as CSR
	GameManager.add_child(csrMenu)
	CSR.Open = true
	return csrMenu


func TestSaveGame() -> void:
	PersistDataManager.SaveGame()

func btnAutoLose() -> void:
	AutoLose = !AutoLose

func ClearCampaignData() -> void:
	PersistDataManager.ClearCampaign()
	pass # Replace with function body.


func btnMarkTutorialComplete() -> void:
	PersistDataManager.universeData.completedCutscenes.append(CutsceneManager.FTUE)
	PersistDataManager.BlockUniverseSave = false
	PersistDataManager.BlockCampaignSave = false
	PersistDataManager.BlockMapSave = false
	PersistDataManager.SaveGame()
	ClearCampaignData()


func ClearCutsceneData() -> void:
	PersistDataManager.universeData.completedCutscenes.clear()
	PersistDataManager.universeData.Save()
	pass # Replace with function body.


func DealDamageToTarget() -> void:
	var unit = GetCurrentHighlighedUnit() as UnitInstance
	if unit != null:
		unit.ModifyHealth(-1, null, true)

func GetCurrentHighlighedUnit():
	if Map.Current == null:
		return null

	if Map.Current.playercontroller != null:
		var currentTile = Map.Current.playercontroller.CurrentTile
		if currentTile != null:
			return Map.Current.playercontroller.CurrentTile.Occupant

	return null
