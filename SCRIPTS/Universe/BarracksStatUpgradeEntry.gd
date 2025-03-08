extends Node
class_name BarracksStatUpgradeEntry

@export var StatBlockEntry : Control
@export var MinusButton : Button
@export var PlusButton : Button
@export var AllocatedUpgradeLabel : Label

var template : StatTemplate
var unitPersist : UnitPersistBase
var Parent : Barracks
var baseStatValue : int
var currentIncrease : int

func ForceFocus():
	MinusButton.grab_focus()

func Initialize(_stat : StatTemplate, _unitTemplate : UnitTemplate, _unitPersistence : UnitPersistBase, _parent : Barracks):
	_parent.OnStatChangedFromPrestiege.connect(Refresh)
	Parent = _parent
	template = _stat
	unitPersist = _unitPersistence

	StatBlockEntry.icon.texture = template.loc_icon
	StatBlockEntry.statName.text = template.loc_displayName_short

	baseStatValue = _unitTemplate.GetBaseStat(_stat)
	Refresh()

func Refresh():
	currentIncrease = unitPersist.GetPrestiegeStatMod(template)
	MinusButton.disabled = currentIncrease <= 0
	PlusButton.disabled = unitPersist.UnallocatedPrestiege <= 0

	StatBlockEntry.statValue.text = "%01.0d" % [(baseStatValue + currentIncrease)]
	AllocatedUpgradeLabel.visible = currentIncrease > 0
	AllocatedUpgradeLabel.text = "+" + str(currentIncrease)

func OnMinus():
	if currentIncrease > 0:
		unitPersist.RemovePrestiegePoint(template)
	Parent.OnStatChangedFromPrestiege.emit()

func OnPlus():
	if unitPersist.UnallocatedPrestiege > 0:
		unitPersist.AddPrestiegePoint(template)
	Parent.OnStatChangedFromPrestiege.emit()
