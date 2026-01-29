extends RequirementBase
class_name MultiRequirement

@export var requirements : Array[RequirementBase]

func CheckRequirement(_context):
	for r in requirements:
		if r == null:
			continue

		var res = r.CheckRequirement(_context)
		if !res && !r.NOT || res && r.NOT:
			return false
	return true
