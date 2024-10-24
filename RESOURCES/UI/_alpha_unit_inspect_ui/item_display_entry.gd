extends Control
class_name ItemDisplayEntry

signal OnSelected

@export var emptyParent : Control
@export var displayParent : Control

@export var icon : TextureRect
@export var itemName : Label
@export var itemDescription : Label

@export var selectedParent : Control


func _ready():
	gui_input.connect(OnGUI)
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func OnGUI(_event : InputEvent):
	if _event.is_action_pressed("select") && selectedParent.visible:
		OnSelected.emit()

func OnFocusEntered():
	if selectedParent != null: selectedParent.visible = true

func OnFocusExited():
	if selectedParent != null: selectedParent.visible = false

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
