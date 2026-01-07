extends Button
class_name RewardEntryPanel

signal OnRewardSelected(reward : LootTableEntry, index : int)


@export var rewardType : Label
@export var rewardIcon : TextureRect
@export var rewardName : Label
@export var rewardDesc : RichTextLabel
var reward : LootTableEntry
var index : int

func Initialize(_reward : LootTableEntry, _index : int):
	reward = _reward
	index = _index

	if reward is ItemRewardEntry:
		InitializeAsItem(reward as ItemRewardEntry)
		return

	if reward is WeaponRewardEntry:
		InitializeAsWeapon(reward as WeaponRewardEntry)
		return

	if reward is SpecificUnitRewardEntry:
		InitializeAsUnit(reward as SpecificUnitRewardEntry)
		return

	pass

func InitializeAsWeapon(_weaponRewardEntry : WeaponRewardEntry):
	var weapon = _weaponRewardEntry.GetWeaponInstance()
	if weapon == null:
		push_error("Weapon to be rewarded in item reward entry is null. This should not happen, and indicates an improperly setup loot table. Please investigate.")
		return

	# TODO: Gotta fix this man it's not a good look
	rewardType.text = "Type: Weapon"
	rewardIcon.texture = weapon.icon
	rewardName.text = tr(weapon.loc_displayName)
	rewardDesc.text = tr(weapon.loc_displayDesc).format(GameManager.LocalizationSettings.FormatAbilityDescription(weapon))
	pass

func InitializeAsItem(_itemRewardEntry : ItemRewardEntry):
	var itemToBeRewarded = _itemRewardEntry.ItemPrefab.instantiate() as UnitUsable

	if itemToBeRewarded == null:
		push_error("Item to be rewarded in item reward entry is null. This should not happen, and indicates an improperly setup loot table. Please investigate.")
		return

	if itemToBeRewarded is Item:
		rewardType.text = "Type: Item"
	elif itemToBeRewarded is Ability:
		if itemToBeRewarded.type == Ability.AbilityType.Weapon:
			rewardType.text = "Type: Weapon"
		else:
			rewardType.text = "Type: Ability"



	rewardIcon.texture = itemToBeRewarded.icon
	rewardName.text = tr(itemToBeRewarded.loc_displayName)
	rewardDesc.text = tr(itemToBeRewarded.loc_displayDesc).format(GameManager.LocalizationSettings.FormatAbilityDescription(itemToBeRewarded))


func InitializeAsUnit(_unitRewardEntry : SpecificUnitRewardEntry):
	rewardType.text = "Type: Unit"
	var unitToBeRewarded = _unitRewardEntry.Unit
	if unitToBeRewarded == null:
		push_error("Unit to be rewarded in specific unit reward entry is null. This should not happen, and indicates an improperly setup loot table. Please investigate")
		return

	rewardIcon.texture = unitToBeRewarded.icon
	rewardName.text = tr(unitToBeRewarded.loc_DisplayName)
	rewardDesc.text = tr(unitToBeRewarded.loc_Description)

func OnEntryPressed():
	OnRewardSelected.emit(reward, index)
