@tool
extends RADataImporterPanel

# This is a dictionary, that is acting as a nested array
# Keys will be indexes and values will be arrays that contain dictionaries
var lootTableData : Dictionary


func import_data_from_json(_data):
	ConstructAllDataMappings()
	modifiedStack = GetAllFilesFromPath(LootTable_Dir)
	var tableIndex = 0

	var workingArray : Array[Dictionary]
	var currentLine = _data[0]["LootTableName"]
	for line in _data:
		var tableName = line["LootTableName"]
		if !tableName.is_empty() && !currentLine.is_empty() && currentLine != tableName:
			lootTableData[tableIndex] = workingArray.duplicate(false)
			workingArray.clear()
			currentLine = tableName
			tableIndex += 1
		workingArray.append(line)

	# the last line still needs to be added
	lootTableData[tableIndex] = workingArray.duplicate(false)

	# reset the index
	tableIndex = 0
	while lootTableData.has(tableIndex):
		var tableName = lootTableData[tableIndex][0]["LootTableName"]
		var path = ConstructPathFromTableName(tableName)
		var lootTable = try_load_loot_table(path, tableName) as LootTable
		if lootTable == null:
			log += str("[color=red]Could not load loot table: [/color]", tableName)
			tableIndex += 1
			continue

		lootTable.Table.clear()
		for line in lootTableData[tableIndex]:
			match line["LootType"]:
				"Item":
					var entry = ImportItemEntry(tableName, line)
					if entry != null:
						lootTable.Table.append(entry)
				"LootTable":
					var entry = ImportLootTableEntry(tableName, line)
					if entry != null:
						lootTable.Table.append(entry)
				"SpecificUnit":
					var entry = ImportSpecificUnitEntry(tableName, line)
					if entry != null:
						lootTable.Table.append(entry)
			pass

		ReCalcWeightSum(lootTable)

		tableIndex += 1
		log += str("\n[color=green]Successfully modified Template [/color]", lootTable.resource_name, "[color=green] At path: [/color]", path)
		var err = ResourceSaver.save(lootTable, path)
		if err != OK:
			log += str("\n[color=red]FAILED TO SAVE LOOT TABLE AT PATH: [/color]", path, "[color=red]ERROR CODE: [/color]", err)

		# Update the modified stack so we can track which files were modified and which files aren't in the spreadsheet anymore
		var indexOfPath = modifiedStack.find(path)
		if indexOfPath != -1:
			modifiedStack.remove_at(indexOfPath)


	for path in modifiedStack:
		log += str("\n[color=pink]Unit Template at path: [/color]", path, " - [color=pink] is no longer in the spreadsheets. You should delete it![/color]")

	errorPanel.text = log
	# man it would have been nice if this example was in the docs somewhere
	var d = ConfirmationDialog.new()
	d.dialog_text = "Import Complete"
	d.title = "Alert"
	add_child(d)
	d.popup_centered()


func ReCalcWeightSum(_lootTable : LootTable):
	_lootTable.WeightSum = 0
	for e in _lootTable.Table:
		if e == null:
			continue

		_lootTable.WeightSum += e.Weight
		e.AccumulatedWeight = _lootTable.WeightSum


func ImportItemEntry(_tableName, _line):
	var itemEntry = ItemRewardEntry.new()
	itemEntry.Weight = _line["Weight"]

	var itemName = _line["Data1"]
	var itemMapIndex = itemNameArray.find(itemName)
	if itemMapIndex == -1:
		log += str("\n[color=red]Could not find item ", itemName, " for an entry in table ", _tableName, " -- skipping entry[/color]")
		return null
	else:
		itemEntry.ItemPrefab = ResourceLoader.load(itemPathArray[itemMapIndex]) as PackedScene
		return itemEntry

func ImportSpecificUnitEntry(_tableName, _line):
	var specificUnitEntry = SpecificUnitRewardEntry.new()
	specificUnitEntry.Weight = _line["Weight"]

	var unitName = _line["Data1"]
	var unitNameIndex = unitNameArray.find(unitName)
	if unitNameIndex == -1:
		log += str("\n[color=red]Could not find Unit ", unitName, " for an entry in table ", _tableName, " -- skipping entry[/color]")
		return null
	else:
		specificUnitEntry.Unit = ResourceLoader.load(unitPathArray[unitNameIndex]) as UnitTemplate
		return specificUnitEntry

func ImportLootTableEntry(_tableName, _line):
	var lootTableEntry = NestedLootTableEntry.new()
	lootTableEntry.Weight = _line["Weight"]

	var nestedTableName = _line["Data1"]
	var lootTableIndex = lootTableArray.find(nestedTableName)
	if lootTableIndex == -1:
		log += str("\n[color=red]Could not find LootTable ", nestedTableName, " for an entry in table ", _tableName, " -- Does it exist yet? This could be fixed on a reimport.[/color]")
		return null
	else:
		lootTableEntry.Table = ResourceLoader.load(lootTablePathArray[lootTableIndex]) as LootTable
		return lootTableEntry

func ConstructPathFromTableName(_tableName : String):
	return str(LootTable_Dir, "/", _tableName, ".tres")

func try_load_loot_table(_path, _tableName):
	print("Attempting to load path:" , _path)
	if ResourceLoader.exists(_path):
		var lootTable = ResourceLoader.load(_path)
		return lootTable as LootTable
	else:
		log += str("\n[color=orange]Failed to find LootTable at path: [/color]", _path, " - [color=orange]Creating new asset at that path[/color]")
		var lootTable = CreateNewLootTable(_path, _tableName)
		return lootTable as LootTable

func CreateNewLootTable(_path, _tableName):
	var newTable = LootTable.new()
	newTable.resource_name = _tableName
	return newTable
