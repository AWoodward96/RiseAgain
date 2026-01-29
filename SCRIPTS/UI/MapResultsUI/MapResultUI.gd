extends FullscreenUI
class_name MapResultUI

signal ResultsComplete()

@export var mapName : Label
@export var continueButton : Button

@export var mainObjectiveParent : EntryList
@export var optionalObjectiveParent : EntryList
@export var objectivePrefab : PackedScene

@export var squadEntryParent : EntryList
@export var squadEntryPrefab : PackedScene


@export var rewardsEntryParent : EntryList
@export var rewardsEntryPrefab : PackedScene

@export var turnCounterLabel : Label
@export var goldAcquiredLabel : Label
@export var goldPerModifierLabel : Label

@export var goldGoUpSound : FmodEventEmitter2D

var map : Map
var campaign : Campaign
var parGoldGained : int

func Initialize(_map : Map):
	map = _map
	campaign = map.CurrentCampaign

	RefreshPar()
	RefreshUnits()
	RefreshObjectives()
	RefreshRewards()
	pass

func RefreshObjectives():
	mainObjectiveParent.ClearEntries()
	var mainEntry = mainObjectiveParent.CreateEntry(objectivePrefab) as MapObjectivePanel
	mainEntry.Refresh(map, map.WinCondition)

	optionalObjectiveParent.ClearEntries()
	for opt in map.OptionalObjectives:
		var optEntry = optionalObjectiveParent.CreateEntry(objectivePrefab) as MapObjectivePanel
		optEntry.Refresh(map, opt.objective)
	pass

func RefreshUnits():
	if GameManager.CurrentCampaign != null:
		for unit in GameManager.CurrentCampaign.CurrentRoster:
			# TODO Should show a dead icon
			if unit == null:
				continue

			var entry = squadEntryParent.CreateEntry(squadEntryPrefab)
			entry.Initialize(unit)
			pass
	else:
		for unit in map.teams[GameSettingsTemplate.TeamID.ALLY]:
			if unit == null:
				continue

			var entry = squadEntryParent.CreateEntry(squadEntryPrefab)
			entry.Initialize(unit)
			pass
	pass

func RefreshRewards():
	if campaign == null:
		return

	# If we're seeing this UI I guess it's safe to assume we've completed the map objective so create one entry for that
	var mainReward = rewardsEntryParent.CreateEntry(rewardsEntryPrefab)
	mainReward.Initialize(map, campaign.GetMapRewardTable())

	for optionalObjectives in map.OptionalObjectives:
		if optionalObjectives.objective == null:
			continue

		if optionalObjectives.objective.CheckObjective(map):
			var optReward = rewardsEntryParent.CreateEntry(rewardsEntryPrefab)
			optReward.Initialize(map, optionalObjectives.rewardTable)

	mainReward.grab_focus()

func RefreshPar():
	turnCounterLabel.text = tr(LocSettings.Current_Max).format({"CUR" = map.turnCount, "MAX" = map.Par})
	parGoldGained = GameManager.GameSettings.CalculatePar(map)
	#goldAcquiredLabel.text = "%+d" % parGoldGained

	var dif = (map.Par - map.turnCount) * GameManager.GameSettings.GoldPercLostPerTurn
	goldPerModifierLabel.text = "%+d%%" % (dif * 100)
	goldPerModifierLabel.visible = false
	pass

func ShowGoldAquisition():
	var newResourceDef = ResourceDef.new()
	newResourceDef.ItemResource = GameManager.GameSettings.GoldResource
	newResourceDef.Amount = GameManager.GameSettings.CalculatePar(map)
	PersistDataManager.universeData.AddResource(newResourceDef, goldAcquiredLabel.global_position)
	pass

func TweenGoldGain():
	var tweenedGain = get_tree().create_tween()
	tweenedGain.tween_method(UpdateGoldGainLabel, 0, parGoldGained, 2.0)
	tweenedGain.tween_callback(GoldGainComplete)

	pass

func UpdateGoldGainLabel(_cur : int):
	goldGoUpSound.play()
	goldAcquiredLabel.text = "%+d" % _cur

func GoldGainComplete():
	goldGoUpSound.stop()
	goldPerModifierLabel.visible = true


func ReturnFocus():
	for rewards in rewardsEntryParent.createdEntries:
		if !rewards.opened:
			rewards.grab_focus()
			return

	continueButton.grab_focus()
	pass


func CloseUI():
	ShowGoldAquisition()
	ResultsComplete.emit()
	queue_free()

func OnContinueButton():
	var cancontinue = true
	for rewards in rewardsEntryParent.createdEntries:
		if !rewards.opened:
			cancontinue = false
			break

	if cancontinue:
		CloseUI()
	else:
		GenericConfirmUI.OpenUI(tr("ui_you_still_have_rewards"), func() : CloseUI(), func() : pass)
		pass

	pass
