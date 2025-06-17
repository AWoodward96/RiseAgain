extends Resource
class_name VariableChance

@export var baseChance : int = 100
@export var modifiers : Array[ChanceModifier]

func EvaluateChance(_context):
	# start with the base chance
	var chance = baseChance
	for mod in modifiers:
		if mod == null:
			continue

		chance = mod.Modify(chance, _context)
	return clamp(chance, 0, 100)
