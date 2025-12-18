extends Resource
class_name LootTable

const INFINITE_LOOP_PROTECTION = 1000

@export var Table : Array[LootTableEntry]

# This should be updated on import
@export var WeightSum : float = -1


func RollTable(rng : DeterministicRNG, _numberOfRewards : int, _duplicateProtections : bool = true):
	var rewardArray : Array[LootTableEntry]
	var infiniteProtection = 0
	while rewardArray.size() < _numberOfRewards:
		var reward = Roll(rng)

		if reward != null:
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


func Roll(rng : DeterministicRNG):
	if rng == null:
		rng = DeterministicRNG.Construct()

	if WeightSum == -1:
		return null

	var rolledValue = rng.NextFloat(0, WeightSum)
	print("Loot Table Rolled: ", rolledValue)
	for entry in Table:
		if entry.AccumulatedWeight > rolledValue && entry.AccumulatedWeight != -1:
			if entry is NestedLootTableEntry:
				if entry.Table.WeightSum == -1:
					entry.Table.ReCalcWeightSum()

				return entry.Table.Roll(rng)
			else:
				return entry

	# If we get here then we somehow traversed the whole table without finding anything. Return null and try again
	return null


func ReCalcWeightSum(_lootTable : LootTable):
	_lootTable.WeightSum = 0
	for e in _lootTable.Table:
		if e == null:
			continue

		if !e.LootRequirement.CheckRequirement(e):
			# This is to indicate that this entry is invalid - because it doesn't pass the requirement
			e.AccumulatedWeight = -1
			continue

		_lootTable.WeightSum += e.Weight
		e.AccumulatedWeight = _lootTable.WeightSum
