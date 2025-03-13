extends LootTable
class_name SpecificLootTable


func RollTable(_rng : DeterministicRNG, _numberOfRewards : int, _duplicateProtections : bool = true):
	var rewardArray : Array[LootTableEntry]
	for i in _numberOfRewards:
		rewardArray.append(Table[i])
	return rewardArray
