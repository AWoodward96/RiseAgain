extends RequirementBase
class_name ItemNotPresentInCampaign

# Not too happy about this, but it's the simplest way without instantiating each item
# every time this requirement is checked
@export var BannedItemsInternalNames : Array[String]

func CheckRequirement(_genericData):
	if GameManager.CurrentCampaign == null:
		return true

	if GameManager.CurrentCampaign.Convoy == null:
		return true

	for bannedName in BannedItemsInternalNames:
		for item in GameManager.CurrentCampaign.Convoy.ItemInventory:
			if item.internalName == bannedName:
				return false

		for weapon in GameManager.CurrentCampaign.Convoy.WeaponInventory:
			if weapon.internalName == bannedName:
				return false

		for ability in GameManager.CurrentCampaign.Convoy.TacticalInventory:
			if ability.internalName == bannedName:
				return false

	return true
