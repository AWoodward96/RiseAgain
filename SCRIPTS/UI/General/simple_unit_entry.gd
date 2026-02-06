extends Control
class_name UnitEntryUI

signal OnSelected(_element : UnitEntryUI, _unitTemplate : UnitTemplate)

@export var button : Button
@export var useIcon : bool = true
@export var icon : TextureRect
@export var useVisualParent : bool = false
@export var visualParent : Control
@export var nameLabel : Label

var Template : UnitTemplate
var CreatedVisual : UnitVisual


func Initialize(_unitTemplate : UnitTemplate):
	Template = _unitTemplate
	if Template == null:
		queue_free()
		return

	if useIcon:
		icon.texture = Template.icon

	if useVisualParent:
		# hate this, but we're gonna merge 2d with control elements
		CreatedVisual = _unitTemplate.VisualPrefab.instantiate() as UnitVisual
		visualParent.add_child(CreatedVisual)
		CreatedVisual.position = Vector2.ZERO
		CreatedVisual.RefreshAllegience(GameSettingsTemplate.TeamID.ALLY)

	nameLabel.text = _unitTemplate.loc_DisplayName

func PlayAnimation(_animationString : String):
	if CreatedVisual != null:
		CreatedVisual.PlayAnimation(_animationString, true)

func OnFocus():
	if useVisualParent && CreatedVisual != null:
		CreatedVisual.PlayAnimation(UnitSettingsTemplate.ANIM_SELECTED, false)
	pass

func OnUnfocus():
	if useVisualParent && CreatedVisual != null:
		CreatedVisual.PlayAnimation(UnitSettingsTemplate.ANIM_IDLE, false)
	pass

func OnButtonPressed():
	OnSelected.emit(self, Template)
