extends FullscreenUI
class_name BarracksUI

signal OnStatChangedFromPrestiege

@export var CurrentUnitIcon : TextureRect
@export var CurrentUnitName : Label
@export var UnitPanel : TeamGridPanel
@export var PrestiegeBar : ProgressBar
@export var PrestiegeBarLabel : Label
@export var PrestiegePointsRemaining : Label
@export var CurrentPrestiegeLevelLabel : Label
@export var StatBlockEntryParent : EntryList
@export var StatBlockEntryPrefab : PackedScene
@export var Animator : AnimationPlayer


var unitSelected : bool
var unitTemplate : UnitTemplate
var unitPersist : UnitPersistBase
var lastSelected : Control

func _ready():
	super()
	UnitPanel.OnUnitSelected.connect(ShowUnitData)
	UnitPanel.OnHoverChanged.connect(UpdatePanelData)
	OnStatChangedFromPrestiege.connect(UpdateAllocatedPrestiege)


func ShowUnitData(_unitTemplate : UnitTemplate):
	unitSelected = true

	UnitPanel.EnableFocus(false)
	UpdatePanelData(_unitTemplate)
	EnableStatBlockFocus(true)
	Animator.play("FocusMods")
	var first = StatBlockEntryParent.GetEntry(0)
	first.ForceFocus()

func UpdatePanelData(_unitTemplate : UnitTemplate):
	unitTemplate = _unitTemplate
	unitPersist = PersistDataManager.universeData.GetUnitPersistence(unitTemplate) as UnitPersistBase
	if unitPersist == null:
		return

	CurrentUnitIcon.texture = _unitTemplate.icon
	CurrentUnitName.text = _unitTemplate.loc_DisplayName

	UpdateAllocatedPrestiege()
	var nextPrestiegeBreakpoint = GameManager.UnitSettings.GetPrestiegeBreakpoint(unitPersist.PrestiegeLevel)
	var perc = float(unitPersist.PrestiegeEXP) / float(nextPrestiegeBreakpoint)
	PrestiegeBar.value = perc
	PrestiegeBarLabel.text = "{0}/{1}".format([str(unitPersist.PrestiegeEXP), str(nextPrestiegeBreakpoint)])

	StatBlockEntryParent.ClearEntries()
	for statTemplate in GameManager.GameSettings.LevelUpStats:
		var entry = StatBlockEntryParent.CreateEntry(StatBlockEntryPrefab)
		entry.Initialize(statTemplate, _unitTemplate, unitPersist, self)


func EnableStatBlockFocus(_enabled : bool):
	for entries in StatBlockEntryParent.createdEntries:
		entries.EnableFocus(_enabled)


func ReturnFocus():
	if unitSelected:
		if StatBlockEntryParent.createdEntries.size() > 0:
			StatBlockEntryParent.createdEntries[0].MinusButton.grab_focus()
		pass
	else:
		UnitPanel.ReturnFocus()
	pass

func UpdateAllocatedPrestiege():
	if unitPersist == null:
		return

	CurrentPrestiegeLevelLabel.text = "%01.0d" % [unitPersist.PrestiegeDisplayLevel]
	PrestiegePointsRemaining.text = "%01.0d" % [unitPersist.UnallocatedPrestiege]
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
