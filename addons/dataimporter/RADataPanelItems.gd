@tool
extends RADataImporterPanel

var instancedItem

func import_data_from_json(_data):
	modifiedStack = GetAllFilesFromPath(Items_Dir)
	for line in _data:
		var filePath = line["filePath"]
		var item = try_load_item(filePath, line)
		ModifyItem(item, filePath, line)

	for path in modifiedStack:
		log += str("\n[color=pink]Item at path: [/color]", path, " - [color=pink] is no longer in the spreadsheets. You should delete it![/color]")

	errorPanel.text = log

	# man it would have been nice if this example was in the docs somewhere
	var d = ConfirmationDialog.new()
	d.dialog_text = "Import Complete"
	d.title = "Alert"
	add_child(d)
	d.popup_centered()

func try_load_item(_path, line):
	print("Attempting to load path:" , _path)
	if ResourceLoader.exists(_path):
		var item : PackedScene = PackedScene.new()
		item = ResourceLoader.load(_path)
		instancedItem = item.instantiate()
		return instancedItem as Item
	else:
		log += str("\n[color=orange]Failed to find Item at path: [/color]", _path, " - [color=orange]Creating new asset at that path[/color]")
		instancedItem = CreateNewItem(_path, line)
		return instancedItem as Item

func CreateNewItem(_path, line):
	var newItem = Item.new()
	newItem.name = line["internal_name"]
	return newItem

func ModifyItem(_item : Item, _filePath, _data):
	if _item == null:
		log += str("\n[color=red]Item at Path [/color]", _filePath ," [color=red]is null. Item will not be imported[/color]")
		return

	if _data.has("internal_name"): _item.internalName = _data["internal_name"]
	if _data.has("loc_name"): _item.loc_displayName = _data["loc_name"]
	if _data.has("loc_desc"): _item.loc_displayDesc = _data["loc_desc"]

	if _data.has("iconPath"):
		if ResourceLoader.exists(_data["iconPath"]):
			var texture = ResourceLoader.load(_data["iconPath"]) as CompressedTexture2D
			_item.icon = texture
		else:
			log += str("\n[color=red]Failed to find Icon for Item [/color]", _item.internalName ," [color=red]at path:[/color]", _data["iconPath"])

	ModifyStatConsumableComponent(_item, _data)
	ModifyStatGrowthModComponent(_item, _data)

	log += str("\n[color=green]Successfully modified Item [/color]", _item.internalName)
	var toSave : PackedScene = PackedScene.new()
	for c in _item.get_children():
		c.set_owner(_item)

	toSave.pack(_item)

	# See https://github.com/godotengine/godot/issues/30302#issuecomment-1140052274
	toSave.take_over_path(_filePath)
	var err = ResourceSaver.save(toSave, _filePath)
	if err != OK:
		log += str("\n[color=red]FAILED TO SAVE ITEM AT PATH: [/color]", _filePath, "[color=red]ERROR CODE: [/color]", err)

	# Update the modified stack so we can track which files were modified and which files aren't in the spreadsheet anymore
	var index = modifiedStack.find(_filePath)
	if index != -1:
		modifiedStack.remove_at(index)
	pass

func ConstructStatDef(_dataRef, value):
	var statDef = StatDef.new()
	var template = ResourceLoader.load(stat_dict[_dataRef])
	statDef.Template = template
	statDef.Value = value
	return statDef

func ModifyStatConsumableComponent(_item : Item, _data):
	if !_data.has("Stat1") || _data["Stat1"] == "":
		return

	var children = _item.get_children()
	var component : HeldItemComponent
	for child in children:
		if child is HeldItemComponent:
			component = child as HeldItemComponent
			break

	if component == null:
		log += str("\n[color=green]No HeldItemComponent detected for item: [/color]", _item.internalName ," [color=green]Creating a new one.[/color]")
		component = HeldItemComponent.new()
		_item.add_child(component)
		component.name = "HeldItemComponent"

	_item.statData = component
	component.StatsToGrant.clear()

	if _data.has("Stat1") && _data.has("Stat1Val"):
		if !_data["Stat1"].is_empty():
			#log += str("\n[color=green]Item has a HeldItemComponent set to true. Here's the stuff it's supposed to read!: [/color]", _data["Stat1"], _data["Stat1Val"])
			component.StatsToGrant.append(ConstructStatDef(_data["Stat1"], _data["Stat1Val"]))
		else:
			log += str("\n[color=orange]Item has a HeldItemComponent set to true, but no stat defined in ConsStat1: [/color]", _item.internalName)


	if _data.has("Stat2") && _data.has("Stat2Val"):
		if !_data["Stat2"].is_empty():
			component.StatsToGrant.append(ConstructStatDef(_data["Stat2"], _data["Stat2Val"]))
	pass

func ModifyStatGrowthModComponent(_item : Item, _data):
	if !_data.has("StatGrowthMod1") || _data["StatGrowthMod1"] == "":
		return

	var children = _item.get_children()
	var component : HeldItemStatGrowthModifier
	for child in children:
		if child is HeldItemStatGrowthModifier:
			component = child as HeldItemStatGrowthModifier
			break

	if component == null:
		log += str("\n[color=green]No HeldItemStatGrowthModifier detected for item: [/color]", _item.internalName ," [color=green]Creating a new one.[/color]")
		component = HeldItemStatGrowthModifier.new()
		_item.add_child(component)
		component.name = "HeldItemStatGrowthModifier"

	_item.growthModifierData = component
	component.GrowthModifiers.clear()

	var count = 1
	while(_data.has("StatGrowthMod" + str(count))):
		var modcolumn = "StatGrowthMod" + str(count)
		var valcolumn = "StatGrowthVal" + str(count)
		if _data.has(modcolumn) && _data.has(modcolumn):
			if !_data[modcolumn].is_empty():
				component.GrowthModifiers.append(ConstructStatDef(_data[modcolumn], _data[valcolumn]))
			else:
				log += str("\n[color=orange]Item has a HeldItemStatGrowthModifier set to true, but no stat defined in ConsStat1: [/color]", _item.internalName)
		count += 1
	pass
