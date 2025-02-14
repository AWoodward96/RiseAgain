extends Resource
class_name ObjectiveReward

@export var loc_objectiveDescription : String
@export var objective : MapObjective
@export var rewardTable : LootTable


func UpdateLocalization(map):
	return objective.UpdateLocalization(map)
