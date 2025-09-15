@tool
extends RADataImporterPanel

const folderStructPrefix = "res://RESOURCES"
const statTemplatePathPrefix = "res://RESOURCES/Stats/"



func import_data_from_json(_data):
	ConstructAllDataMappings()
	modifiedStack = GetAllFilesFromPath(Units_Dir)
	modifiedStack = modifiedStack.filter(FilterOutVIS)
	for line in _data:
		var filePath = line["filePath"]
		if filePath.is_empty():
			continue

		var unitTemplate = try_load_unit_template(filePath, line)
		ModifyUnitTemplate(unitTemplate, filePath, line)

	for path in modifiedStack:
		log += str("\n[color=pink]Unit Template at path: [/color]", path, " - [color=pink] is no longer in the spreadsheets. You should delete it![/color]")

	errorPanel.text = log
	# man it would have been nice if this example was in the docs somewhere
	var d = ConfirmationDialog.new()
	d.dialog_text = "Import Complete"
	d.title = "Alert"
	add_child(d)
	d.popup_centered()


func try_load_unit_template(_path, _line):

	print("Attempting to load path:" , _path)
	if ResourceLoader.exists(_path):
		var unitTemplate = ResourceLoader.load(_path)
		return unitTemplate as UnitTemplate
	else:
		log += str("\n[color=orange]Failed to find Unit at path: [/color]", _path, " - [color=orange]Creating new asset at that path[/color]")
		var unitTemplate = CreateNewUnitTemplate(_path, _line)
		return unitTemplate as UnitTemplate


func CreateNewUnitTemplate(_path, _line):
	var newUnit = UnitTemplate.new()
	newUnit.resource_name = _line["Template"]

	var directoryPath = str(Units_Dir, "/", _line["allegiance"],"/",_line["internal_name"])
	var globalizedPath = ProjectSettings.globalize_path(directoryPath)
	if !DirAccess.dir_exists_absolute(globalizedPath):
		var err = DirAccess.make_dir_recursive_absolute(globalizedPath)
		if err != OK:
			push_error("CREATE DIRECTORY ERROR: ", err)

	return newUnit


func ModifyUnitTemplate(_unitTemplate : UnitTemplate, _path : String, _data):
	if _unitTemplate == null:
		return

	if _data.has("loc_name"): _unitTemplate.loc_DisplayName = _data["loc_name"]

	if _data.has("loc_desc"): _unitTemplate.loc_Description = _data["loc_desc"]

	if _data.has("affinity") && _data["affinity"] != "":
		if affinity_dict.has(_data["affinity"]):
			var affinity = ResourceLoader.load(affinity_dict[_data["affinity"]]) as AffinityTemplate
			if affinity != null:
				_unitTemplate.Affinity = affinity
		else:
			log += str("\n[color=orange]Failed to find Affinity: [/color]", _data["affinity"], " - [color=orange]Did you spell it right?[/color]")

	ModifyUnitStat(_unitTemplate, stat_dict["Vitality"], _data["Vitality"])
	ModifyUnitStat(_unitTemplate, stat_dict["Attack"], _data["Attack"])
	ModifyUnitStat(_unitTemplate, stat_dict["Defense"], _data["Defense"])
	ModifyUnitStat(_unitTemplate, stat_dict["SpAttack"], _data["SpAttack"])
	ModifyUnitStat(_unitTemplate, stat_dict["SpDefense"], _data["SpDefense"])
	ModifyUnitStat(_unitTemplate, stat_dict["Movement"], _data["Movement"])
	ModifyUnitStat(_unitTemplate, stat_dict["Luck"], _data["Luck"])
	ModifyUnitStat(_unitTemplate, stat_dict["Mind"], _data["Mind"])

	ModifyUnitStatGrowths(_unitTemplate, stat_dict["Vitality"], _data["gVitality"])
	ModifyUnitStatGrowths(_unitTemplate, stat_dict["Attack"], _data["gAttack"])
	ModifyUnitStatGrowths(_unitTemplate, stat_dict["Defense"], _data["gDefense"])
	ModifyUnitStatGrowths(_unitTemplate, stat_dict["SpAttack"], _data["gSpAttack"])
	ModifyUnitStatGrowths(_unitTemplate, stat_dict["SpDefense"], _data["gSpDefense"])
	ModifyUnitStatGrowths(_unitTemplate, stat_dict["Luck"], _data["gLuck"])

	if _data.has("internal_name"): _unitTemplate.DebugName = _data["internal_name"]

	if _data.has("loc_icon"):
		var icon_path = _data["loc_icon"]
		var icon = ResourceLoader.load(icon_path) as Texture2D
		if icon != null:
			_unitTemplate.icon = icon
		else:
			log += str("\n[color=red]Failed to load icon for unit at path: [/color]", icon_path, " - File not found")

	ImportWeapon(_unitTemplate, _data)
	ImportTactical(_unitTemplate, _data)
	ImportDescriptors(_unitTemplate, _data)
	ImportWeaponDescriptors(_unitTemplate, _data)

	# NOTE:
	# Okay so it's tempting to put the flag: ResourceSaver.FLAG_BUNDLE_RESOURCES
	# Here in this save method, because based on documentation I'd need it. The UnitTemplates contain nested Resources in the form of their Stats
	# But for some reason putting that flag in here completely breaks all references when I reload the editor.
	# The UnitTemplates' scripts get replaced with a UnitTemplates#134crs34 cached script reference and it breaks everyhing to hell and back
	# I think for now this works, as far as I can tell. The StatRefs get populated properly
	log += str("\n[color=green]Successfully modified Template [/color]", _unitTemplate.DebugName)
	var err = ResourceSaver.save(_unitTemplate, _path)
	if err != OK:
		log += str("\n[color=red]FAILED TO SAVE UNIT TEMPLATE AT PATH: [/color]", _path, "[color=red]ERROR CODE: [/color]", err)

	# Update the modified stack so we can track which files were modified and which files aren't in the spreadsheet anymore
	var index = modifiedStack.find(_path)
	if index != -1:
		modifiedStack.remove_at(index)

func ModifyUnitStat(_unitTemplate : UnitTemplate, _statPath : String, _value):
	var statDefs = _unitTemplate.BaseStats
	var statTemplate = load(_statPath)
	var found = false
	if statTemplate:
		for def in statDefs:
			if def.Template == statTemplate:
				def.Value = _value
				found = true

		if !found:
			var statDef = StatDef.new()
			statDef.Template = statTemplate
			statDef.Value = _value
			_unitTemplate.BaseStats.append(statDef)

func ModifyUnitStatGrowths(_unitTemplate : UnitTemplate, _statPath : String, _value):
	var statDefs = _unitTemplate.StatGrowths
	var statTemplate = load(_statPath)
	var found = false
	if statTemplate:
		for def in statDefs:
			if def.Template == statTemplate:
				def.Value = _value
				found = true

		if !found:
			var statDef = StatDef.new()
			statDef.Template = statTemplate
			statDef.Value = _value
			_unitTemplate.StatGrowths.append(statDef)

func ImportWeapon(_unitTemplate : UnitTemplate, _data):
	var weap_as_stringname = _data["Base_Equipped_Weapon"]
	if weap_as_stringname.is_empty():
		return

	var index = unlockableNameArray.find(weap_as_stringname)
	if index != -1:
		var weapon = ResourceLoader.load(unlockablePathArray[index]) as AbilityUnlockable
		_unitTemplate.StartingEquippedWeapon = weapon

func ImportTactical(_unitTemplate : UnitTemplate, _data):
	var tactical_as_stringname = _data["Tactical"]
	if tactical_as_stringname.is_empty():
		return

	var index = unlockableNameArray.find(tactical_as_stringname)
	if index != -1:
		var tactical = ResourceLoader.load(unlockablePathArray[index]) as AbilityUnlockable
		_unitTemplate.StartingTactical = tactical

func ImportDescriptors(_unitTemplate: UnitTemplate, _data):
	_unitTemplate.Descriptors.clear()
	for i in range(0,2):
		var descriptor_as_stringname = _data[str("Descriptors[",i,"]")]
		if descriptor_as_stringname.is_empty():
			continue

		# since these are parallel arrays, I should just be able to lookup the index of the item name, and map it to the path in the directory array
		var index = descriptorNameArray.find(descriptor_as_stringname)
		if index != -1:
			var descriptor = ResourceLoader.load(descriptorPathArray[index]) as DescriptorTemplate
			_unitTemplate.Descriptors.append(descriptor)

func ImportWeaponDescriptors(_unitTemplate : UnitTemplate, _data):
	_unitTemplate.WeaponDescriptors.clear()
	if _data.has("AllowedWeapons"):
		var descString = _data["AllowedWeapons"] as String
		var split = descString.split(',')
		for descriptorID in split:
			var trimmed = descriptorID.strip_edges()
			if !trimmed.is_empty():
				var index = descriptorNameArray.find(trimmed)
				if index != -1:
					var foundDescriptorTemplate = ResourceLoader.load(descriptorPathArray[index]) as DescriptorTemplate
					_unitTemplate.WeaponDescriptors.append(foundDescriptorTemplate)
				else:
					log += str("\n[color=red]Could not find weapon descriptor: [/color]", trimmed, "[color=red]Please ensure that the descriptor exists before importing[/color]")
