extends Control
class_name UnitEntryUI

signal OnSelected(_element : UnitEntryUI, _unitTemplate : UnitTemplate)

@export var useIcon : bool = true
@export var icon : TextureRect
@export var useVisualParent : bool = false
@export var visualParent : Control
@export var nameLabel : Label

var template : UnitTemplate
var createdVisual : UnitVisual


func Initialize(_unitTemplate : UnitTemplate):
	template = _unitTemplate

	if useIcon:
		icon.texture = template.icon

	if useVisualParent:
		# hate this, but we're gonna merge 2d with control elements
		createdVisual = _unitTemplate.VisualPrefab.instantiate() as UnitVisual
		visualParent.add_child(createdVisual)
		createdVisual.position = Vector2.ZERO
		createdVisual.RefreshAllegience(GameSettingsTemplate.TeamID.ALLY)

	nameLabel.text = _unitTemplate.loc_DisplayName

func OnFocus():
	if useVisualParent && createdVisual != null:
		createdVisual.PlayAnimation(UnitSettingsTemplate.ANIM_SELECTED, false)
	pass

func OnUnfocus():
	if useVisualParent && createdVisual != null:
		createdVisual.PlayAnimation(UnitSettingsTemplate.ANIM_IDLE, false)
	pass

func OnButtonPressed():
	OnSelected.emit(self, template)
