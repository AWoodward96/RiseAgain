extends Control
class_name MapObjectivePanel

@export var objectiveText : Label
@export var rewardParent : Control
@export var completedParent : Control

func Refresh(_map : Map, _objective : MapObjective):
	var completed = _objective.CheckObjective(_map)

	if objectiveText != null: objectiveText.text = _objective.UpdateLocalization(_map)
	if rewardParent != null: rewardParent.visible = completed
	if completedParent != null: completedParent.visible = completed
	pass
