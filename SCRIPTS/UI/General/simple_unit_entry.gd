extends Control
class_name UnitEntryUI

signal OnSelected(_element : Control, _unitTemplate : UnitTemplate)

@export var icon : TextureRect
@export var nameLabel : Label
@export var hoverParent : Control

var template : UnitTemplate
var beingHovered : bool

func Initialize(_unitTemplate : UnitTemplate):
	template = _unitTemplate
	icon.texture = template.icon
	nameLabel.text = _unitTemplate.loc_DisplayName

func SetFocus(_bool : bool):
	beingHovered = _bool
	if hoverParent != null:
		hoverParent.visible = _bool

func _on_focus_entered() -> void:
	SetFocus(true)

func _on_focus_exited() -> void:
	SetFocus(false)

func _process(_delta: float) -> void:
	if InputManager.selectDown && beingHovered && focus_mode != Control.FocusMode.FOCUS_NONE:
		OnSelected.emit(self, template)
