extends TopdownInteractable
class_name Barracks

signal OnStatChangedFromPrestiege

@export var UIParent : Node
@export var Anim : AnimationPlayer

@export_category("UI")
@export var PrestiegeBar : ProgressBar
@export var PrestiegeBarLabel : Label
@export var UnitEntryParent : EntryList
@export var UnitEntryPrefab : PackedScene
@export var StatBlockEntryParent : EntryList
@export var StatBlockEntryPrefab : PackedScene
@export var BlockUpgradeArea : Control


var hasInteractable : bool
var unitSelected : bool
var unitTemplate : UnitTemplate
var element : Control

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
	if _bool && !hasInteractable:
		Anim.play("Show")
		InitializeUI()
	hasInteractable = _bool

func InitializeUI():
	CreateUnitEntries()
	pass

func CreateUnitEntries():
	UnitEntryParent.ClearEntries()
	for u in PersistDataManager.universeData.unitPersistData:
		if u.Alive: #&& u.Unlocked:
			var entry = UnitEntryParent.CreateEntry(UnitEntryPrefab)
			entry.Initialize(u.Template)
			entry.OnSelected.connect(ShowUnitData)

	UnitEntryParent.FocusFirst()
	pass

func ShowUnitData(_element : Control, _unitTemplate : UnitTemplate):
	var persistData = PersistDataManager.universeData.GetUnitPersistence(_unitTemplate) as UnitPersistBase
	if persistData == null:
		return

	unitSelected = true
	unitTemplate = _unitTemplate
	element = _element
	Anim.play("FocusMods")
	var nextPrestiegeBreakpoint = GameManager.UnitSettings.GetPrestiegeBreakpoint(persistData.PrestiegeLevel)
	var perc = float(persistData.PrestiegeEXP) / float(nextPrestiegeBreakpoint)
	PrestiegeBar.value = perc
	PrestiegeBarLabel.text = "{0}/{1}".format([str(persistData.PrestiegeEXP), str(nextPrestiegeBreakpoint)])

	StatBlockEntryParent.ClearEntries()
	for statTemplate in GameManager.GameSettings.LevelUpStats:
		var entry = StatBlockEntryParent.CreateEntry(StatBlockEntryPrefab)
		entry.Initialize(statTemplate, unitTemplate, persistData, self)

	UnitEntryParent.SetEntryFocus(Control.FOCUS_NONE)
	var first = StatBlockEntryParent.GetEntry(0)
	first.ForceFocus()
	element.SetFocus(true)


func _process(_delta: float) -> void:
	if InputManager.cancelDown && hasInteractable:
		if unitSelected:
			unitSelected = false
			UnitEntryParent.SetEntryFocus(Control.FOCUS_ALL)
			element.grab_focus()
			Anim.play("FocusEntries")
		else:
			TopDownPlayer.BlockInputCounter -= 1
			SetInteractable(false)
