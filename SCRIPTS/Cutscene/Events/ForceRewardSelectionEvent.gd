extends CutsceneEventBase
class_name ForceRewardSelectionEvent

@export var RewardIndex : int = -1

var actionComplete = false

func Enter(_context : CutsceneContext):
	if RewardsUI.Instance == null:
		return false

	actionComplete = false
	RewardsUI.Instance.ForcedRewardChoice = RewardIndex
	RewardsUI.Instance.OnRewardSelected.connect(RewardSelected)
	return true

func Execute(_delta, _context : CutsceneContext):
	return actionComplete

func RewardSelected(_reward : LootTableEntry, _unit : UnitInstance):
	actionComplete = true

func Exit(_context : CutsceneContext):
	if RewardsUI.Instance != null:
		if RewardsUI.Instance.OnRewardSelected.is_connected(RewardSelected):
			RewardsUI.Instance.OnRewardSelected.disconnect(RewardSelected)
