@tool
extends Control
class_name POIAdjacencyData

@export var Neighbor : POI
@export var Requirement : Array[RequirementBase]
@export var Direction : GameSettingsTemplate.Direction :
	set(_val):
		Direction = _val
		RefreshName()
@export var Traversable : bool = true :
	set(_val):
		Traversable = _val
		RefreshName()

func RefreshName():
	name = "{0}_{1}".format([GameSettingsTemplate.Direction.keys()[Direction], str(Traversable)])


func PassesRequirement():
	var passed = true
	for r in Requirement:
		var rPass = r.CheckRequirement(null)
		if  !r.NOT:
			passed = passed && rPass
		elif r.NOT:
			passed = passed && !rPass

	return passed
