extends Control
class_name SmithyEntryTabUI


@export var smithyEntryPrefab : PackedScene
@export var smithyEntryParent : EntryList
@export var filterDescriptors : DescriptorTemplate


func _ready():
	if visible:
		Refresh()
	pass

func Refresh():
	smithyEntryParent.ClearEntries()
	var index = 0
	for levels : SmithyBuildingLevel in GameManager.GameSettings.SmithyData.Levels:
		if levels == null:
			continue

		for unlock : SmithyWeaponUnlockDef in levels.Unlocks:
			if filterDescriptors != null:
				if !unlock.unlockableTemplate.Descriptors.has(filterDescriptors):
					continue

			var entry = smithyEntryParent.CreateEntry(smithyEntryPrefab)
			if entry != null:
				entry.Initialize(unlock, index)

		index += 1

	smithyEntryParent.FocusFirst()

	pass

func ReturnFocus():
	smithyEntryParent.FocusFirst()
