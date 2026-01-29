extends AnchoredUIElement
class_name ObjectivePanel

@export var ObjectiveText : Label
@export var OptionalObjectiveParent : Control
@export var OptionalObjectiveText : Label

func RefreshObjective(map : Map):
	ObjectiveText.text = map.WinCondition.UpdateLocalization(map)
	if map.OptionalObjectives.size() > 0:
		OptionalObjectiveParent.visible = true

		# For now only do the first one
		var firstOptional = map.OptionalObjectives[0]
		OptionalObjectiveText.text = firstOptional.UpdateLocalization(map)
	else:
		OptionalObjectiveParent.visible = false
