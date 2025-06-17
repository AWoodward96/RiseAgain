extends LootTable
class_name SpecificLootTable


func RollTable(_rng : DeterministicRNG, _numberOfRewards : int, _duplicateProtections : bool = true):
	var rewardArray : Array[LootTableEntry]
	for i in _numberOfRewards:
		if Table[i] is NestedLootTableEntry:
			rewardArray.append_array(Table[i].Table.RollTable(_rng, 1, _duplicateProtections))
		else:
			rewardArray.append(Table[i])
	return rewardArray
