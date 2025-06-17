extends Resource
class_name EventDecision

@export var option_loc : String
@export var resultspreview_loc : Array[MadLibLoc]

### If true, if the requirement is not met, do not show this as an option
@export var hiddenRequirement : bool
@export var requirements : Array[RequirementBase]

@export var resultActionStack : Array[CutsceneEventBase]
