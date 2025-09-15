extends Control
class_name AbilityShortformUI

@export var icon : TextureRect
@export var nameLabel : Label
@export var contentParent : Control
@export var noneParent : Control

func Initialize(_ability : Ability):
	if _ability == null:
		contentParent.visible = false
		noneParent.visible = true
	else:
		contentParent.visible = true
		noneParent.visible = false
		icon.texture = _ability.icon
		nameLabel.text = _ability.loc_displayName
