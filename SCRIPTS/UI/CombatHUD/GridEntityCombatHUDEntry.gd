extends Node
class_name GridEntityCombatHUDEntry

@export var icon : TextureRect
@export var loc_label : Label

func Update(_gridEntity : GridEntityBase, _onTile : Tile):
	icon.texture = _gridEntity.localization_icon
	loc_label.text = _gridEntity.GetLocalizedDescription(_onTile)
