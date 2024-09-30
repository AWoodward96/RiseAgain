extends Control
class_name ItemDisplayEntry

@export var emptyParent : Control
@export var displayParent : Control

@export var icon : TextureRect
@export var itemName : Label
@export var itemDescription : Label


func Refresh(_item : Item):
	if _item == null:
		emptyParent.visible = true
		displayParent.visible = false
		return

	emptyParent.visible = false
	displayParent.visible = true

	icon.texture = _item.icon
	itemName.text = _item.loc_displayName
	itemDescription.text = _item.loc_displayDesc
