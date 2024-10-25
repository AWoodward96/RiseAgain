extends MapStateBase
class_name VictoryState

var combatHUD : CombatHUD
var rewardUI : RewardsUI

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	controller.EnterVictoryState()

	combatHUD = controller.combatHUD
	if combatHUD != null:
		combatHUD.PlayVictoryBanner()
		await combatHUD.BannerAnimComplete

	# TODO : Item selection, or Unit Selection
	if map.CurrentCampaign != null:
		# Start the reward selection process
		var campaign = map.CurrentCampaign
		var rewardTable = campaign.GetMapRewardTable() as LootTable
		if rewardTable != null:
			# Roll the rewards for the rewardTable
			var rewardArray = rewardTable.RollTable(campaign.CampaignRng, GameManager.GameSettings.NumberOfRewardsInPostMap)

			# open the rewards ui
			rewardUI = GameManager.MapRewardUI.instantiate() as RewardsUI
			map.add_child(rewardUI)

			rewardUI.Initialize(rewardArray, map.CurrentCampaign, OnRewardsSelected)
			await rewardUI.OnRewardSelected

		for optionalObjectives in map.OptionalObjectives:
			if optionalObjectives.objective == null:
				continue

			if optionalObjectives.objective.CheckObjective(map):
				var rewardArray = optionalObjectives.rewardTable.RollTable(campaign.CampaignRng, GameManager.GameSettings.NumberOfRewardsInPostMap)
				rewardUI = GameManager.MapRewardUI.instantiate() as RewardsUI
				map.add_child(rewardUI)

				rewardUI.Initialize(rewardArray, map.CurrentCampaign, OnRewardsSelected)
				await rewardUI.OnRewardSelected


	await map.get_tree().create_timer(1).timeout

	var signalCallback = GameManager.ShowLoadingScreen()
	await signalCallback

	if map.CurrentCampaign != null:
		map.CurrentCampaign.MapComplete()

	pass

func OnRewardsSelected(_lootRewardEntry : LootTableEntry, _unit : UnitInstance):
	rewardUI.queue_free()

	if _lootRewardEntry is SpecificUnitRewardEntry:
		map.CurrentCampaign.AddUnitToRoster(_lootRewardEntry.Unit)
		return

	if _lootRewardEntry is ItemRewardEntry :
		# Default to giving the first person in the roster the item
		if _unit == null:
			push_error("Can't give reward to a null unit. Item has been sent to convoy")
		else:
			var counter = 0
			var equipped = false
			for slot in _unit.ItemSlots:
				if slot == null:
					_unit.EquipItem(counter, _lootRewardEntry.ItemPrefab)
					equipped = true
					break
				counter += 1

			if !equipped:
				map.CurrentCampaign.AddItemToConvoy(_lootRewardEntry.ItemPrefab)

	pass

func Exit():
	pass

func Update(_delta):
	pass


func ToString():
	return "VictoryState"
