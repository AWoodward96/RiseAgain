extends Resource
class_name RequirementBase

@export var NOT : bool


# Requirements are supposed to be flexible ways of checking if something can be done
# And because Godot supports generic typings, I'm going to abuse that.
# This script can be used for combat effects, or out of combat effects
# until I figure out a scenario where I cannot do this, and then i'll have to split out the logic to seperate scripts
func CheckRequirement(_genericData):
	return true
