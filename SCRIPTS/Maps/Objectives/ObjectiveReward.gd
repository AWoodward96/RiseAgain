extends Resource
class_name ObjectiveReward

@export var objective : MapObjective
@export var rewardTable : LootTable


func UpdateLocalization(map):
	return objective.UpdateLocalization(map)
