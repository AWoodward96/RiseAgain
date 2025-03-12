extends MultipanelBase

@export var InspectUI : UnitInspectUI
@export var itemSlotEntryList : EntryList
@export var itemSlotEntry : PackedScene

var unit : UnitInstance

func OnVisiblityChanged():
	if InspectUI != null:
		unit = InspectUI.unit
		RefreshEntries()
		if visible:
			itemSlotEntryList.FocusFirst()
	pass

func RefreshEntries():
	itemSlotEntryList.ClearEntries()
	for item in unit.ItemSlots:
		var entry = itemSlotEntryList.CreateEntry(itemSlotEntry)
		entry.Refresh(item)
