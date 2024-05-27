extends Control

signal OnItemSelected

@onready var item_icon: TextureRect = %ItemIcon
@onready var item_name: Label = %ItemName
@onready var selected_parent: ColorRect = %SelectedParent
var selected
var currentItem

func _ready():
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func Initialize(_item : Item):
	currentItem = _item
	item_icon.texture = _item.icon
	item_name.text = _item.loc_displayName

func _process(delta: float):
	if selected && InputManager.selectDown:
		OnItemSelected.emit()

func OnFocusEntered():
	selected = true
	selected_parent.visible = true

	if currentItem.TargetingData != null:
		currentItem.ShowRangePreview()

func OnFocusExited():
	selected = false
	selected_parent.visible = false
