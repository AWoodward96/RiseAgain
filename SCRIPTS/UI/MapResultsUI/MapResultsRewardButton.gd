extends Button
class_name MapResultsRewardButton

@export var closedVis : TextureRect
@export var openedVis : TextureRect

var opened = false
var lootTable : LootTable
var map : Map
var rewardUI : RewardsUI

func Initialize(_map : Map, _lootTable : LootTable):
	lootTable = _lootTable
	map = _map
	closedVis.visible = true
	openedVis.visible = false
	pass

func OnPressed():
	opened = true
	closedVis.visible = false
	openedVis.visible = true

	var rewardArray = lootTable.RollTable(map.CurrentCampaign.CampaignRng, GameManager.GameSettings.NumberOfRewardsInPostMap)

	# open the rewards ui
	rewardUI = UIManager.OpenFullscreenUI(UIManager.MapRewardUI)
	rewardUI.Initialize(rewardArray, map.CurrentCampaign, OnRewardsSelected)
	disabled = true

func OnRewardsSelected(_lootRewardEntry : LootTableEntry, _unit : UnitInstance):
	rewardUI.queue_free()

	if _lootRewardEntry is SpecificUnitRewardEntry:
		map.CurrentCampaign.AddUnitToRoster(_lootRewardEntry.Unit)
		return

	if _lootRewardEntry is ItemRewardEntry || _lootRewardEntry is WeaponRewardEntry :
		# Default to giving the first person in the roster the item
		if _unit != null:
			# NOTE: if Unit is null, then the item has been sent to the convoy via a different sequence
			# But if it's not null, it's handled here - lets gooo
			if _lootRewardEntry is WeaponRewardEntry :
				_unit.AddAbilityInstance(_lootRewardEntry.GetWeaponInstance())
			elif _lootRewardEntry is ItemRewardEntry:
				if !_unit.TryEquipItem(_lootRewardEntry.ItemPrefab):
					map.CurrentCampaign.Convoy.AddToConvoy(_lootRewardEntry.ItemPrefab.instantiate())


	pass
