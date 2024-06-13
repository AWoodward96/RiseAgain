extends Resource
class_name LootTable

const INFINITE_LOOP_PROTECTION = 1000

@export var Table : Array[LootTableEntry]

# This should be updated on import
@export var WeightSum : float = -1


func RollTable(rng : RandomNumberGenerator, _numberOfRewards : int, _duplicateProtections : bool = true):
	var rewardArray : Array[LootTableEntry]
	var infiniteProtection = 0
	while rewardArray.size() < _numberOfRewards:
		var reward = Roll(rng)
		if _duplicateProtections:
			var index = rewardArray.find(reward)
			if index == -1: # should be -1 if there is no duplicates
				rewardArray.append(reward)
		else:
			rewardArray.append(reward)

		# this will hopefully break us out
		infiniteProtection += 1
		if infiniteProtection >= INFINITE_LOOP_PROTECTION:
			push_error("Infinite Loop Protection when trying to roll ", _numberOfRewards, " times on table ", self.resource_name)
			return rewardArray
	return rewardArray


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
