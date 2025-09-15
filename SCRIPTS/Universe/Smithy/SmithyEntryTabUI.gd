extends Control
class_name SmithyEntryTabUI

@export var smithyEntryPrefab : PackedScene
@export var smithyEntryParent : EntryList
@export var filterDescriptors : DescriptorTemplate

var sectionalLabels : Array[Label]

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
				entry.InitWithSmithyWeaponData(unlock, index)
				entry.OnPressed.connect(TryPurchase)

		index += 1

	smithyEntryParent.FocusFirst()

	pass

func TryPurchase(_entry : SmithyWeaponEntryUI):
	if _entry.lockedBySmithyLevel:
		_entry.LockedBySmithyLevelFailed()
		return

	if _entry.alreadyUnlocked:
		_entry.AlreadyUnlockedFailed()
		return

	if PersistDataManager.universeData.HasResourceCost(_entry.data.cost.cost):
		ConfirmPurchaseUI.OpenUI(_entry.data.cost.cost,
			func() :
				PersistDataManager.universeData.TryPayPackedResourceCost(_entry.data.cost, PurchaseSuccess.bind(_entry), PurchaseFailed),
			func():
				pass)
		pass
	else:
		_entry.NotEnoughResourceFailed()
		pass


func PurchaseSuccess(_entry : SmithyWeaponEntryUI):
	PersistDataManager.universeData.UnlockUnlockable(_entry.data.unlockableTemplate)
	Refresh()
	pass

func PurchaseFailed():
	Refresh()
	pass


func ReturnFocus():
	smithyEntryParent.FocusFirst()
