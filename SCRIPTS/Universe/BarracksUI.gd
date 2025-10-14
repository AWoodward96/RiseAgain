extends FullscreenUI
class_name BarracksUI

signal OnStatChangedFromPrestiege

@export var UnitPanel : TeamGridPanel
@export var PrestiegeBar : ProgressBar
@export var PrestiegeBarLabel : Label
@export var StatBlockEntryParent : EntryList
@export var StatBlockEntryPrefab : PackedScene
@export var Animator : AnimationPlayer


var unitSelected : bool
var unitTemplate : UnitTemplate
var lastSelected : Control

func _ready():
	super()
	UnitPanel.OnUnitSelected.connect(ShowUnitData)


func ShowUnitData(_unitTemplate : UnitTemplate):
	var persistData = PersistDataManager.universeData.GetUnitPersistence(_unitTemplate) as UnitPersistBase
	if persistData == null:
		return

	unitSelected = true
	unitTemplate = _unitTemplate
	UnitPanel.EnableFocus(false)
	var nextPrestiegeBreakpoint = GameManager.UnitSettings.GetPrestiegeBreakpoint(persistData.PrestiegeLevel)
	var perc = float(persistData.PrestiegeEXP) / float(nextPrestiegeBreakpoint)
	PrestiegeBar.value = perc
	PrestiegeBarLabel.text = "{0}/{1}".format([str(persistData.PrestiegeEXP), str(nextPrestiegeBreakpoint)])

	StatBlockEntryParent.ClearEntries()
	for statTemplate in GameManager.GameSettings.LevelUpStats:
		var entry = StatBlockEntryParent.CreateEntry(StatBlockEntryPrefab)
		entry.Initialize(statTemplate, unitTemplate, persistData, self)

	EnableStatBlockFocus(true)
	Animator.play("FocusMods")
	var first = StatBlockEntryParent.GetEntry(0)
	first.ForceFocus()

func EnableStatBlockFocus(_enabled : bool):
	for entries in StatBlockEntryParent.createdEntries:
		entries.EnableFocus(_enabled)



func ReturnFocus():
	if unitSelected:
		pass
	else:
		UnitPanel.ReturnFocus()
	pass


func _process(_delta: float) -> void:
	if InputManager.cancelDown:
		if unitSelected:
			unitSelected = false
			UnitPanel.EnableFocus(true)
			EnableStatBlockFocus(false)
			Animator.play("FocusEntries")
		else:
			TopDownPlayer.BlockInputCounter -= 1
