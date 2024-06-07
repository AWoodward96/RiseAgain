extends Resource
class_name LootTable

@export var Table : Array[LootTableEntry]

# This should be updated on import
@export var WeightSum : float = -1

func ReCalcWeightSum():
	WeightSum = 0
	for e in Table:
		if e == null:
			continue

		WeightSum += e.Weight
		e.AccumulatedWeight = WeightSum

	# HACK: I should NOT be doing this here, but BOY is it nice that I can. Consider.... removing this...
	ResourceSaver.save(self, resource_path)

func Roll(rng : RandomNumberGenerator):
	if rng == null:
		rng = RandomNumberGenerator.new()

	if WeightSum == -1:
		push_error("WEIGHT SUM IS INVALID FOR ", self.resource_name, " IF YOU SEE THIS AT RUNTIME THEN YOU'RE PROBABLY FUCKED LMAO. GOOD LUCK!")
		return null

	var rolledValue = rng.randf_range(0, WeightSum)
	print("Loot Table Rolled: ", rolledValue)
	for entry in Table:
		if entry.AccumulatedWeight > rolledValue:
			if entry is NestedLootTableEntry:
				if entry.Table.WeightSum == -1:
					entry.Table.ReCalcWeightSum()

				return entry.Table.Roll(rng)
			else:
				return entry
