extends Control
class_name MapResultsUnitEntryMicro

@export var visualParent : Control
@export var bgColor : ColorRect
@export var colorNormal : Color
@export var colorInjured : Color
@export var colorDead : Color
@export var injuredPopup : Control
@export var iconDeadParent : Control

var createdVisual : UnitVisual
var unitTemplate : UnitTemplate
var unitInstance : UnitInstance

func Initialize(_unitInstance : UnitInstance):
	unitTemplate = _unitInstance.Template
	unitInstance = _unitInstance
	CreateVisual()
	UpdateBG()
	pass

func CreateVisual():
	createdVisual = unitTemplate.VisualPrefab.instantiate() as UnitVisual
	visualParent.add_child(createdVisual)
	createdVisual.position = Vector2.ZERO
	createdVisual.RefreshAllegience(GameSettingsTemplate.TeamID.ALLY)

func UpdateBG():
	iconDeadParent.visible = false
	if unitInstance.currentHealth <= 0:
		bgColor.color = colorDead
		iconDeadParent.visible = true
		createdVisual.PlayAnimation("take_damage", true)
		return

	if unitInstance.Injured:
		bgColor.color = colorInjured
		injuredPopup.visible = true
		createdVisual.PlayAnimation("run_right", true)
		return

	injuredPopup.visible = false
	bgColor.color = colorNormal
	createdVisual.PlayAnimation("run_right", true)
