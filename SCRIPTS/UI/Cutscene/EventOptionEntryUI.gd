extends InspectableElement
class_name EventOptionEntryUI

const TITLE_SIZE = 20
const OPTION_SIZE = 16

@export var DynamicSizingElement : Control
@export var OptionText : RichTextLabel
@export var ResultsParents : Array[Control]
@export var ResultsTexts : Array[RichTextLabel]
@export var ReqFailColor : Color

var visibleResults : int = 0
var decisionIndex = -1

func Initialize(_eventDecision : EventDecision, _requirementMet : bool, _index : int, _context):
	# Requirement should be handled by the parent ui
	OptionText.text = _eventDecision.option_loc
	decisionIndex = _index

	visibleResults = 0
	for i in range(0, ResultsParents.size()):
		if i < _eventDecision.resultspreview_loc.size():
			ResultsParents[i].visible = true
			ResultsTexts[i].text = _eventDecision.resultspreview_loc[i].GetString(_context)
			visibleResults += 1
		else:
			ResultsParents[i].visible = false

	DynamicSizingElement.custom_minimum_size = Vector2(0, TITLE_SIZE + (OPTION_SIZE * visibleResults))
	DynamicSizingElement.update_minimum_size()
	DynamicSizingElement.modulate = Color.WHITE

	if !_requirementMet:
		DynamicSizingElement.modulate = ReqFailColor
	SetDisabled(!_requirementMet)
	pass
