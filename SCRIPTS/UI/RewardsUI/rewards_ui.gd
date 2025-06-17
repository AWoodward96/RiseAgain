extends CanvasLayer
class_name RewardsUI

static var Instance : RewardsUI

signal OnRewardSelected(_reward : LootTableEntry, _unit : UnitInstance)

@export var ShowSelectionDelay : float = 1
@export var rewardEntryPrefab : PackedScene
@export var rewardParent : EntryList

@export_category("Give Item")
@export var giveItemParent : Control
@export var giveItemEntryPrefab : PackedScene
@export var giveItemEntryList : EntryList
@export var giveItemIcon : TextureRect

var showSelectionTimer : float = 0
var campaign : Campaign
var workingSelectedReward : LootTableEntry
var allRewards : Array[LootTableEntry]
var ForcedRewardChoice : int = -1


func _ready() -> void:
	Instance = self

func _exit_tree() -> void:
	Instance = null

func Initialize(_rewards : Array[LootTableEntry], _campaign : Campaign, _callback : Callable):
	giveItemParent.visible = false
	campaign = _campaign
	allRewards = _rewards
	showSelectionTimer = 0

	rewardParent.ClearEntries()
	var index = 0
	for r in allRewards:
		var e = rewardParent.CreateEntry(rewardEntryPrefab)
		e.Initialize(r, index)
		e.OnRewardSelected.connect(OnEntrySelected)
		index += 1

	rewardParent.FocusFirst()
	OnRewardSelected.connect(_callback)
	pass

func _process(_delta: float):
	if showSelectionTimer < ShowSelectionDelay:
		showSelectionTimer += _delta

	if InputManager.cancelDown && giveItemParent.visible:
		giveItemParent.visible = false
		var index = allRewards.find(workingSelectedReward)
		if index != -1:
			var entry = rewardParent.GetEntry(index)
			if entry != null:
				entry.grab_focus()
		else:
			rewardParent.FocusFirst()

func OnEntrySelected(_reward : LootTableEntry, _index : int):
	# block rapid selection just in case the player is spamming the button
	if showSelectionTimer < ShowSelectionDelay:
		return

	if ForcedRewardChoice != -1 && _index != ForcedRewardChoice:
		return

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
		if unit == null:
			continue

		var entry = giveItemEntryList.CreateEntry(giveItemEntryPrefab)
		entry.Initialize(unit.Template)
		entry.OnUnitSelected.connect(OnUnitSelectedForItem.bind(unit))

	giveItemEntryList.FocusFirst()
	pass

func OnSendToConvoy():
	# If we're here than the campaign kinda has to exist right?
	if campaign != null:
		campaign.AddItemToConvoy(workingSelectedReward.ItemPrefab.instantiate())
		OnRewardSelected.emit(workingSelectedReward, null)
	pass

func OnUnitSelectedForItem(_unit : UnitInstance):
	OnRewardSelected.emit(workingSelectedReward, _unit)
