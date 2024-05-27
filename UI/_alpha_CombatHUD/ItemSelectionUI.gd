extends Control
class_name ItemSelectionUI

signal OnItemSelectedForCombat(_item : Item)

@export var inventoryEntryPrefab : PackedScene

@onready var inventory_item_parent: EntryList = %InventoryItemParent
@onready var item_desc_label: Label = %ItemDescLabel

var currentUnit : UnitInstance
var createdInventoryEntries : Array[Control]


func Initialize(_unit : UnitInstance):
	currentUnit = _unit
	RefreshInventory()

func RefreshInventory():
	inventory_item_parent.ClearEntries()
	for item in currentUnit.Inventory:
		if item == null || item.TargetingData == null:
			continue

		var e = inventory_item_parent.CreateEntry(inventoryEntryPrefab)
		e.Initialize(item)
		e.OnItemSelected.connect(OnItemSelected.bind(item))

	var firstEntry = inventory_item_parent.GetEntry(0)
	if firstEntry != null:
		firstEntry.grab_focus()

func OnItemSelected(_item : Item):
	if _item != null:
		OnItemSelectedForCombat.emit(_item)
