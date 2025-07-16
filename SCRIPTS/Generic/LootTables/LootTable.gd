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
		if _duplicateProtections:
			# don't allow for the same units in the party
			if reward is SpecificUnitRewardEntry:
				var specificUnitRewardEntry = reward as SpecificUnitRewardEntry
				var currentCampaign = GameManager.CurrentCampaign
				var isUnique = true
				if currentCampaign != null:
					for u in currentCampaign.CurrentRoster:
						# Ignore the dead units on your team. The campaign cleans them up later
						if u == null:
							continue

						if u.Template == specificUnitRewardEntry.Unit:
							isUnique = false
							break

					for u in currentCampaign.DeadUnits:
						if u != null && u == specificUnitRewardEntry.Unit:
							isUnique = false
							break

				if !isUnique:
					continue

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
		push_error("WEIGHT SUM IS INVALID FOR ", self.resource_name, " IF YOU SEE THIS AT RUNTIME THEN YOU'RE PROBABLY FUCKED LMAO. GOOD LUCK!")
		return null

	var rolledValue = rng.NextFloat(0, WeightSum)
	print("Loot Table Rolled: ", rolledValue)
	for entry in Table:
		if entry.AccumulatedWeight > rolledValue:
			if entry is NestedLootTableEntry:
				if entry.Table.WeightSum == -1:
					entry.Table.ReCalcWeightSum()

				return entry.Table.Roll(rng)
			else:
				return entry


func ReCalcWeightSum(_lootTable : LootTable):
	_lootTable.WeightSum = 0
	for e in _lootTable.Table:
		if e == null:
			continue

		_lootTable.WeightSum += e.Weight
		e.AccumulatedWeight = _lootTable.WeightSum
