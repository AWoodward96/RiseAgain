extends InspectableElement
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

	if emptyParent != null: emptyParent.visible = false
	if displayParent != null: displayParent.visible = true

	if icon != null: icon.texture = _item.icon
	if itemName != null: itemName.text = _item.loc_displayName
	if itemDescription != null: itemDescription.text = _item.loc_displayDesc
