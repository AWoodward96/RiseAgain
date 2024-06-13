extends CanvasLayer
class_name RewardsUI

signal OnRewardSelected(_reward : LootTableEntry, _unit : UnitInstance)
@export var rewardEntryPrefab : PackedScene
@export var rewardParent : EntryList

@export_category("Give Item")
@export var giveItemParent : Control
@export var giveItemEntryPrefab : PackedScene
@export var giveItemEntryList : EntryList
@export var giveItemIcon : TextureRect

var campaign : CampaignTemplate
var workingSelectedReward : LootTableEntry
var allRewards : Array[LootTableEntry]

func Initialize(_rewards : Array[LootTableEntry], _campaign : CampaignTemplate, _callback : Callable):
	giveItemParent.visible = false
	campaign = _campaign
	allRewards = _rewards

	rewardParent.ClearEntries()
	for r in allRewards:
		var e = rewardParent.CreateEntry(rewardEntryPrefab)
		e.Initialize(r)
		e.OnRewardSelected.connect(OnEntrySelected)

	rewardParent.FocusFirst()
	OnRewardSelected.connect(_callback)
	pass

func _process(_delta: float):
	if InputManager.cancelDown && giveItemParent.visible:
		giveItemParent.visible = false
		var index = allRewards.find(workingSelectedReward)
		if index != -1:
			var entry = rewardParent.GetEntry(index)
			if entry != null:
				entry.grab_focus()
		else:
			rewardParent.FocusFirst()

func OnEntrySelected(_reward : LootTableEntry):
	workingSelectedReward = _reward
	if _reward is SpecificUnitRewardEntry:
		OnRewardSelected.emit(_reward, null)
		return

	if _reward is ItemRewardEntry:
		ShowGiveItemUI()

func ShowGiveItemUI():
	giveItemParent.visible = true
	giveItemEntryList.ClearEntries()

	if workingSelectedReward is ItemRewardEntry:
		var itemToBeRewarded = (workingSelectedReward as ItemRewardEntry).ItemPrefab.instantiate() as Item
		if itemToBeRewarded == null:
			push_error("Item to be rewarded in item reward entry is null. This should not happen, and indicates an improperly setup loot table. Please investigate")
			return
		giveItemIcon.texture = itemToBeRewarded.icon

	for unit in campaign.CurrentRoster:
		var entry = giveItemEntryList.CreateEntry(giveItemEntryPrefab)
		entry.Initialize(unit.Template)
		entry.OnUnitSelected.connect(OnUnitSelectedForItem.bind(unit))

	giveItemEntryList.FocusFirst()
	pass

func OnUnitSelectedForItem(_unit : UnitInstance):
	OnRewardSelected.emit(workingSelectedReward, _unit)

