extends Button
class_name RewardEntryPanel

signal OnRewardSelected(reward : LootTableEntry)


@export var rewardType : Label
@export var rewardIcon : TextureRect
@export var rewardName : Label
@export var rewardDesc : Label
var reward : LootTableEntry

func Initialize(_reward : LootTableEntry):
	reward = _reward

	if reward is ItemRewardEntry:
		InitializeAsItem(reward as ItemRewardEntry)
		return

	if reward is SpecificUnitRewardEntry:
		InitializeAsUnit(reward as SpecificUnitRewardEntry)
		return

	pass

func InitializeAsItem(_itemRewardEntry : ItemRewardEntry):
	rewardType.text = "Type: Item"
	var itemToBeRewarded = _itemRewardEntry.ItemPrefab.instantiate() as Item
	if itemToBeRewarded == null:
		push_error("Item to be rewarded in item reward entry is null. This should not happen, and indicates an improperly setup loot table. Please investigate")
		return

	rewardIcon.texture = itemToBeRewarded.icon
	rewardName.text = itemToBeRewarded.loc_displayName
	rewardDesc.text = itemToBeRewarded.loc_displayDesc

func InitializeAsUnit(_unitRewardEntry : SpecificUnitRewardEntry):
	rewardType.text = "Type: Unit"
	var unitToBeRewarded = _unitRewardEntry.Unit
	if unitToBeRewarded == null:
		push_error("Unit to be rewarded in specific unit reward entry is null. This should not happen, and indicates an improperly setup loot table. Please investigate")
		return

	rewardIcon.texture = unitToBeRewarded.icon
	rewardName.text = unitToBeRewarded.loc_DisplayName
	rewardDesc.text = unitToBeRewarded.loc_Description

func OnEntryPressed():
	OnRewardSelected.emit(reward)

