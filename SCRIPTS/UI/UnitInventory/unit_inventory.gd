extends CanvasLayer

signal OnClose

@export var unit_inventory_panel : UnitInventoryPanel
@export var unit_stat_block : UnitInfoBlock
@export var inventory_context_parent: Control

@onready var equip_button: Button = %EquipButton
@onready var use_button: Button = %UseButton
@onready var trash_button: Button = %TrashButton

var currentUnit : UnitInstance
var selectedItem : Item

func Initialize(_unitInstance : UnitInstance):
	currentUnit = _unitInstance
	inventory_context_parent.visible = false
	Refresh()

func Refresh():
	if unit_inventory_panel != null:
		unit_inventory_panel.Initialize(currentUnit, null)
		if !unit_inventory_panel.ItemSelected.is_connected(OnItemSelected):
			unit_inventory_panel.ItemSelected.connect(OnItemSelected)

	if unit_stat_block != null:
		unit_stat_block.Initialize(currentUnit)

func _process(_delta: float):
	if InputManager.cancelDown:
		if selectedItem != null:
			inventory_context_parent.visible = false
			var entry = unit_inventory_panel.GetEntry(currentUnit.Inventory.find(selectedItem))
			entry.grab_focus()
			selectedItem = null
		else:
			Close()

func OnItemSelected(_item : Item):
	selectedItem = _item
	inventory_context_parent.visible = true

	if _item.TargetingData != null:
		equip_button.visible = true
		equip_button.grab_focus()
		use_button.visible = false
	else:
		use_button.visible = true
		equip_button.visible = false
		use_button.grab_focus()


	var entry = unit_inventory_panel.GetEntry(currentUnit.Inventory.find(_item))
	if entry != null:
		entry.ForceShowFocused()
	pass

func OnUseButton():
	# Yes, do it in this order. Closing shows the Context menu, but OnUse changes the controller state, which hides it
	# Doing it the other way around leaves the context menu open
	Close()
	selectedItem.OnUse()
	pass

func OnTrashButton():
	currentUnit.TrashItem(selectedItem)
	OnActionTaken()
	pass


func OnActionTaken():
	inventory_context_parent.visible = false
	Refresh()
	selectedItem = null

func Close():
	OnClose.emit()
	queue_free()
