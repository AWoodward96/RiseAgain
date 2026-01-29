extends Node
class_name GridEntityCombatHUDEntry

@export var ownerIcon : TextureRect
@export var icon : TextureRect
@export var loc_label : Label

func Update(_gridEntity : GridEntityBase, _onTile : Tile):
	if _gridEntity.Source != null:
		ownerIcon.visible = true
		ownerIcon.texture = _gridEntity.Source.Template.icon
	else:
		ownerIcon.visible = false
	icon.texture = _gridEntity.localization_icon
	loc_label.text = _gridEntity.GetLocalizedDescription(_onTile)
