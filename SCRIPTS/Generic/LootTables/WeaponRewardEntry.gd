extends LootTableEntry
class_name WeaponRewardEntry

# WeaponRewardEntry could use a parent "UnlockableRewardEntry" that has ItemUnlockable and this just inherrits from it

@export var ItemUnlockable : AbilityUnlockable

func GetWeaponInstance():
	if ItemUnlockable != null:
		return load(ItemUnlockable.AbilityPath).instantiate() as Ability
	else:
		return null
