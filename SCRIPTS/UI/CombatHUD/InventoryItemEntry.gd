extends Control

signal OnItemSelected

@onready var item_icon: TextureRect = %ItemIcon
@onready var item_name: Label = %ItemName
@onready var selected_parent: ColorRect = %SelectedParent
@onready var item_usage: Label = %ItemUsage

var selected
var currentItem : Item

func _ready():
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func Initialize(_item : Item):
	currentItem = _item
	item_icon.texture = _item.icon
	item_name.text = _item.loc_displayName

	item_usage.visible = _item.uses >= 0
	item_usage.text = str(_item.uses)

func _process(_delta: float):
	if selected && InputManager.selectDown:
		OnItemSelected.emit()

func OnFocusEntered():
	selected = true
	selected_parent.visible = true

	# Item handles if the targeting data is null, so for consumables it should just clear the target selection
	currentItem.ShowRangePreview()

func OnFocusExited():
	selected = false
	selected_parent.visible = false

func ForceShowFocused():
	selected_parent.visible = true
