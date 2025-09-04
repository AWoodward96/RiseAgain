extends MapStateBase
class_name VictoryState

var combatHUD : CombatHUD
var rewardUI : RewardsUI

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	controller.EnterEndGameState()

	if _map.mapType == _map.MAPTYPE.Standard:
		combatHUD = controller.combatHUD
		if combatHUD != null:
			AudioManager.PlayVictoryStinger()
			if _map.Biome != null && _map.Biome.VictoryDelay > 0:
				await GameManager.get_tree().create_timer(_map.Biome.VictoryDelay).timeout

			combatHUD.PlayVictoryBanner()
			await combatHUD.BannerAnimComplete

		if map.CurrentCampaign != null:
			# Start the reward selection process
			var campaign = map.CurrentCampaign
			var rewardTable = campaign.GetMapRewardTable() as LootTable
			if rewardTable != null:
				# Roll the rewards for the rewardTable
				var rewardArray = rewardTable.RollTable(campaign.CampaignRng, GameManager.GameSettings.NumberOfRewardsInPostMap)

				# open the rewards ui
				rewardUI = UIManager.MapRewardUI.instantiate() as RewardsUI
				map.add_child(rewardUI)

				rewardUI.Initialize(rewardArray, map.CurrentCampaign, OnRewardsSelected)
				await rewardUI.OnRewardSelected

			for optionalObjectives in map.OptionalObjectives:
				if optionalObjectives.objective == null:
					continue

				if optionalObjectives.objective.CheckObjective(map):
					var rewardArray = optionalObjectives.rewardTable.RollTable(campaign.CampaignRng, GameManager.GameSettings.NumberOfRewardsInPostMap)
					rewardUI = UIManager.MapRewardUI.instantiate() as RewardsUI
					map.add_child(rewardUI)

					rewardUI.Initialize(rewardArray, map.CurrentCampaign, OnRewardsSelected)
					await rewardUI.OnRewardSelected


	var signalCallback = GameManager.ShowLoadingScreen()
	await signalCallback.ScreenObscured

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
		if _unit != null:
			# NOTE: if Unit is null, then the item has been sent to the convoy via a different sequence
			# But if it's not null, it's handled here - lets gooo
			if !_unit.TryEquipItem(_lootRewardEntry.ItemPrefab):
				map.CurrentCampaign.AddItemToConvoy(_lootRewardEntry.ItemPrefab.instantiate())
	pass

func Exit():
	pass

func Update(_delta):
	pass

func ToString():
	return "VictoryState"

func ToJSON():
	return "VictoryState"
