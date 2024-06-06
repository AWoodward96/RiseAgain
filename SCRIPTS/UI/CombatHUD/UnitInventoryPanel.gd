extends Control
class_name UnitInventoryPanel

signal ItemSelected(_item : Item)

@export var inventoryEntryPrefab : PackedScene

@onready var inventory_item_parent: EntryList = %InventoryItemParent
@onready var item_desc_label: Label = %ItemDescLabel

@export var HideConsumables : bool  = false
var currentUnit : UnitInstance


func Initialize(_unitInstance : UnitInstance):
	currentUnit = _unitInstance
	inventory_item_parent.ClearEntries()
	for item in currentUnit.Inventory:
		if item == null || (item.TargetingData == null && HideConsumables):
			continue

		var e = inventory_item_parent.CreateEntry(inventoryEntryPrefab)
		e.Initialize(item)
		e.OnItemSelected.connect(OnItemSelected.bind(item))

	var firstEntry = inventory_item_parent.GetEntry(0)
	if firstEntry != null:
		firstEntry.grab_focus()

func OnItemSelected(_item : Item):
	if _item != null:
		ItemSelected.emit(_item)

func GetEntry(_index : int):
	return inventory_item_parent.GetEntry(_index)
