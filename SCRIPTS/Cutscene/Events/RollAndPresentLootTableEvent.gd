extends CutsceneEventBase
class_name RollAndPresentLootTable


@export var Table : LootTable
@export var NumberOfPulls : int = 3

@export var SaveInContext : bool = false

var rewardUI : RewardsUI
var rewardSequenceComplete = false
var context : CutsceneContext

func Enter(_context : CutsceneContext):
	context = _context
	# Roll the rewards for the rewardTable
	rewardSequenceComplete = false

	var rng = DeterministicRNG.Construct()
	if GameManager.CurrentCampaign != null:
		rng = GameManager.CurrentCampaign.CampaignRng
	elif Map.Current != null:
		rng = Map.Current.mapRNG

	var rewardArray = Table.RollTable(rng, NumberOfPulls, true)

	# open the rewards ui
	rewardUI = UIManager.MapRewardUI.instantiate() as RewardsUI
	CutsceneManager.add_child(rewardUI)

	rewardUI.Initialize(rewardArray, Map.Current.CurrentCampaign, OnRewardsSelected)
	return true


func Execute(_delta : float, _context : CutsceneContext):
	return rewardSequenceComplete

func OnRewardsSelected(_lootRewardEntry : LootTableEntry, _unit : UnitInstance):
	rewardUI.queue_free()
	rewardSequenceComplete = true


	if _lootRewardEntry is SpecificUnitRewardEntry:
		if GameManager.CurrentCampaign != null:
			var instance = GameManager.CurrentCampaign.AddUnitToRoster(_lootRewardEntry.Unit)
			if SaveInContext:
				context.ContextDict[CutsceneContext.UNIT_REWARD_SAVESTRING] = instance
		else:
			if SaveInContext:
				context.ContextDict[CutsceneContext.UNIT_REWARD_SAVESTRING] = _lootRewardEntry.Unit
		return

	if _lootRewardEntry is ItemRewardEntry :
		if SaveInContext:
			context.ContextDict[CutsceneContext.ITEM_REWARD_SAVESTRING] = _lootRewardEntry.ItemPrefab.resource_path

		# Default to giving the first person in the roster the item
		if _unit != null:
			# NOTE: if Unit is null, then the item has been sent to the convoy via a different sequence
			# But if it's not null, it's handled here - lets gooo
			if !_unit.TryEquipItem(_lootRewardEntry.ItemPrefab):
				GameManager.CurrentCampaign.AddItemToConvoy(_lootRewardEntry.ItemPrefab.instantiate())
	pass
