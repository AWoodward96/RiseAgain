extends Node2D
class_name ConditionalStatModComponent

@export var StatsToGrant : Array[ConditionalStatDef]


func GetStatChange(_statTemplate : StatTemplate, _context):
	var change = 0
	for conditional in StatsToGrant:
		if conditional.Template == _statTemplate:
			for req in conditional.requirements:
				var res = req.CheckRequirement(_context)
				if !res && req.NOT || res && !req.NOT:
					change += conditional.Value

	return change
