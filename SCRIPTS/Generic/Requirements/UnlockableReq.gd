extends RequirementBase
class_name UnlockableReq

@export var unlockable : UnlockableContentTemplate
@export var useMidRunDiscoverable : bool = false


func CheckRequirement(_genericData):
	if unlockable == null:
		return true

	if useMidRunDiscoverable:
		if unlockable is AbilityUnlockable:
			return unlockable.StartsDiscoverable

	var persistedUnlockable = PersistDataManager.universeData.GetUnlockablePersist(unlockable)
	if persistedUnlockable == null:
		return false

	return persistedUnlockable.Unlocked
