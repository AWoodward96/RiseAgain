extends Control

@export var table : LootTable
@export var parent : Control

var rng : DeterministicRNG

func _ready():
	rng = DeterministicRNG.Construct()

func OnRollPressed():
	table.ReCalcWeightSum(table)
	var result = table.Roll(rng)

	var label = Label.new()
	if result is ItemRewardEntry:
		var item = result.ItemPrefab.instantiate()

		label.text = item.loc_displayName

	parent.add_child(label)
