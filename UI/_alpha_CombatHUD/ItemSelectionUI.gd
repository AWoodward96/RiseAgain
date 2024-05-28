extends Control
class_name ItemSelectionUI

signal OnItemSelectedForCombat(_item : Item)

@export var InventoryPanel : UnitInventoryPanel
var currentUnit : UnitInstance


func Initialize(_unit : UnitInstance):
	currentUnit = _unit
	InventoryPanel.Initialize(currentUnit)

	if !InventoryPanel.ItemSelected.is_connected(OnItemSelected):
		InventoryPanel.ItemSelected.connect(OnItemSelected)


func OnItemSelected(_item : Item):
	if _item != null:
		OnItemSelectedForCombat.emit(_item)
