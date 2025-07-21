@tool
extends RADataImporterPanel

var instancedAbility : Ability

func import_data_from_json(_data):
	ConstructAllDataMappings()
	modifiedStack = GetAllFilesFromPath(Ability_Dir)
	for line in _data:
		var filePath = line["filePath"]
		var item = try_load_ability(filePath, line)
		ModifyAbility(item, filePath, line)

	for path in modifiedStack:
		log += str("\n[color=pink]Ability at path: [/color]", path, " - [color=pink] is no longer in the spreadsheets. You should delete it![/color]")

	errorPanel.text = log

	var d = ConfirmationDialog.new()
	d.dialog_text = "Import Complete"
	d.title = "Alert"
	add_child(d)
	d.popup_centered()

func try_load_ability(_path, line):
	print("Attempting to load path:" , _path)
	if ResourceLoader.exists(_path):
		var ability : PackedScene = PackedScene.new()
		ability = ResourceLoader.load(_path)
		instancedAbility = ability.instantiate()
		return instancedAbility as Ability
	else:
		log += str("\n[color=orange]Failed to find Item at path: [/color]", _path, " - [color=orange]Creating new asset at that path[/color]")
		instancedAbility = CreateNewAbility(_path, line)
		return instancedAbility as Ability

func CreateNewAbility(_path, line):
	var newItem = Ability.new()
	newItem.name = line["internal_name"]
	return newItem

func ModifyAbility(_ability : Ability, _filePath, _data):
	if _ability == null:
		log += str("\n[color=red]Ability at Path [/color]", _filePath ," [color=red]is null. Ability will not be imported[/color]")
		return

	if _data.has("item_type"):
		match _data["item_type"]:
			"Equippable":
				_ability.type = Ability.AbilityType.Weapon
			"Standard":
				_ability.type = Ability.AbilityType.Standard
			"Tactical":
				_ability.type = Ability.AbilityType.Tactical
			"Passive":
				_ability.type = Ability.AbilityType.Passive


	if _data.has("internal_name"): _ability.internalName = _data["internal_name"]
	if _data.has("loc_name"): _ability.loc_displayName = _data["loc_name"]
	if _data.has("loc_desc"): _ability.loc_displayDesc = _data["loc_desc"]
	if _data.has("UsageLimit"): _ability.limitedUsage = int(_data["UsageLimit"])
	if _data.has("AbilityCooldown"): _ability.abilityCooldown = int(_data["AbilityCooldown"])
	if _data.has("UsageRestoredByCampfire"): _ability.usageRestoredByCampfire = int(_data["UsageRestoredByCampfire"])

	if _data.has("iconPath"):
		if ResourceLoader.exists(_data["iconPath"]):
			var texture = ResourceLoader.load(_data["iconPath"]) as CompressedTexture2D
			_ability.icon = texture
		else:
			log += str("\n[color=red]Failed to find Icon for Item [/color]", _ability.internalName ," [color=red]at path:[/color]", _data["iconPath"])


	if _data.has("HasStats") && _data["HasStats"]:
		ModifyItemStatComponent(_ability, _data)

	if _data.has("DoesDamage") && _data["DoesDamage"]:
		ModifyDamageDataComponent(_ability, _data)

	if _data.has("IsTargeted") && _data["IsTargeted"]:
		ModifyTargetingComponent(_ability, _data)

	if _data.has("IsHeal") && _data["IsHeal"]:
		ModifyHealComponent(_ability, _data)

	log += str("\n[color=green]Successfully modified Ability [/color]", _ability.internalName)
	var toSave : PackedScene = PackedScene.new()
	for c in _ability.get_children():
		c.set_owner(_ability)

	toSave.pack(_ability)

	# See https://github.com/godotengine/godot/issues/30302#issuecomment-1140052274
	toSave.take_over_path(_filePath)
	var err = ResourceSaver.save(toSave, _filePath)
	if err != OK:
		log += str("\n[color=red]FAILED TO SAVE ABILITY AT PATH: [/color]", _filePath, "[color=red]ERROR CODE: [/color]", err)

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

func ModifyDamageDataComponent(_ability : Ability, _data):
	var children = _ability.get_children()
	var component : DamageData
	for child in children:
		if child is DamageData:
			component = child as DamageData
			break

	if component == null:
		log += str("\n[color=green]No DamageData detected for item: [/color]", _ability.internalName ," [color=green]Creating a new one.[/color]")
		component = DamageData.new()
		_ability.add_child(component)
		component.name = "DamageComponent"

	_ability.UsableDamageData = component
	if _data.has("Flat Value"): component.FlatValue = _data["Flat Value"]
	if _data.has("Aggressive Mod"): component.AgressiveMod = _data["Aggressive Mod"]
	if _data.has("Defensive Mod"): component.DefensiveMod = _data["Defensive Mod"]

	if _data.has("Aggressive Stat"):
		if _data["Aggressive Stat"].is_empty():
			component.AgressiveStat = null
		else:
			var template = ResourceLoader.load(stat_dict[_data["Aggressive Stat"]])
			component.AgressiveStat = template

	if _data.has("Defensive Stat"):
		if _data["Defensive Stat"].is_empty():
			component.DefensiveStat = null
		else:
			var template = ResourceLoader.load(stat_dict[_data["Defensive Stat"]])
			component.DefensiveStat = template

	if _data.has("Aggressive Mod Type"):
		match _data["Aggressive Mod Type"]:
			"None":
				component.AgressiveModType = DamageData.ModificationType.None
			"Additive":
				component.AgressiveModType = DamageData.ModificationType.Additive
			"Multiplicative":
				component.AgressiveModType = DamageData.ModificationType.Multiplicative
			"Divisitive":
				component.AgressiveModType = DamageData.ModificationType.Divisitive

	if _data.has("Defensive Mod Type"):
		match _data["Defensive Mod Type"]:
			"None":
				component.DefensiveModType = DamageData.ModificationType.None
			"Additive":
				component.DefensiveModType = DamageData.ModificationType.Additive
			"Multiplicative":
				component.DefensiveModType = DamageData.ModificationType.Multiplicative
			"Divisitive":
				component.DefensiveModType = DamageData.ModificationType.Divisitive


	if _data.has("Drain"): component.DamageAffectsUsersHealth = _data["Drain"]
	if _data.has("DamageToHealthRatio"): component.DamageToHealthRatio = _data["DamageToHealthRatio"]

	component.VulerableDescriptors.clear()
	for i in range(0,1):
		var stringConcat = "Vulnerability" + str(i)
		if _data.has(stringConcat):
			var vuln_as_string = _data[stringConcat]

			if !vuln_as_string.is_empty():
				var index = vulnerabilityNameArray.find(vuln_as_string)
				if index != -1:
					var descriptor = ResourceLoader.load(vulnerabilityPathArray[index]) as DescriptorMultiplier
					component.VulerableDescriptors.append(descriptor)

func ModifyItemStatComponent(_ability : Ability, _data):
	var children = _ability.get_children()
	var component : ItemStatComponent
	for child in children:
		if child is ItemStatComponent:
			component = child as ItemStatComponent
			break

	if component == null:
		log += str("\n[color=green]No ItemStatComponent detected for item: [/color]", _ability.internalName ," [color=green]Creating a new one.[/color]")
		component = ItemStatComponent.new()
		_ability.add_child(component)
		component.name = "StatComponent"

	_ability.StatData = component
	if _data.has("BaseAccuracy"): component.BaseAccuracy = _data["BaseAccuracy"]

	component.GrantedStats.clear()
	if _data.has("Stat1") && _data.has("Stat1Val"):
		component.GrantedStats.append(ConstructStatDef(_data["Stat1"], _data["Stat1Val"]))

	if _data.has("Stat2") && _data.has("Stat2Val") && !_data["Stat2"].is_empty():
		component.GrantedStats.append(ConstructStatDef(_data["Stat2"], _data["Stat2Val"]))

	if _data.has("Stat3") && _data.has("Stat3Val") && !_data["Stat3"].is_empty():
		component.GrantedStats.append(ConstructStatDef(_data["Stat3"], _data["Stat3Val"]))

	pass

func ModifyHealComponent(_ability : Ability, _data):
	var children = _ability.get_children()
	var component : HealComponent
	for child in children:
		if child is HealComponent:
			component = child as HealComponent
			break

	if component == null:
		log += str("\n[color=green]No HealComponent detected for item: [/color]", _ability.internalName ," [color=green]Creating a new one.[/color]")
		component = HealComponent.new()
		_ability.add_child(component)
		component.name = "HealComponent"

	_ability.HealData = component
	if _data.has("HealFlatValue"): component.FlatValue = _data["HealFlatValue"]

	if _data.has("HealScalingStat"):
		if _data["HealScalingStat"].is_empty():
			component.ScalingStat = null
		else:
			var template = ResourceLoader.load(stat_dict[_data["HealScalingStat"]])
			component.ScalingStat = template

	if _data.has("HealScalingMod"): component.ScalingMod = _data["HealScalingMod"]

	if _data.has("HealScalingModType"):
		match _data["HealScalingModType"]:
			"None":
				component.ScalingModType = DamageData.ModificationType.None
			"Additive":
				component.ScalingModType = DamageData.ModificationType.Additive
			"Multiplicative":
				component.ScalingModType = DamageData.ModificationType.Multiplicative
			"Divisitive":
				component.ScalingModType = DamageData.ModificationType.Divisitive


func ModifyTargetingComponent(_ability : Ability, _data):
	var children = _ability.get_children()
	var component : SkillTargetingData
	for child in children:
		if child is SkillTargetingData:
			component = child as SkillTargetingData
			break

	if component == null:
		log += str("\n[color=green]No SkillTargetingData detected for item: [/color]", _ability.internalName ," [color=green]Creating a new one.[/color]")
		component = SkillTargetingData.new()
		_ability.add_child(component)
		component.name = "TargetingData"

	_ability.TargetingData = component

	if _data.has("CanTargetSelf"): component.CanTargetSelf = _data["CanTargetSelf"]

	var range : Vector2i
	if _data.has("MinRange"): range.x = _data["MinRange"]
	if _data.has("MaxRange"): range.y = _data["MaxRange"]
	component.TargetRange = range

	if _data.has("TeamTargeting"):
		match _data["TeamTargeting"]:
			"Enemy":
				component.TeamTargeting = SkillTargetingData.TargetingTeamFlag.EnemyTeam
			"Ally":
				component.TeamTargeting = SkillTargetingData.TargetingTeamFlag.AllyTeam
			"All":
				component.TeamTargeting = SkillTargetingData.TargetingTeamFlag.All
			"Empty":
				component.TeamTargeting = SkillTargetingData.TargetingTeamFlag.Empty

	if _data.has("TargetType"):
		match _data["TargetType"]:
			"Simple":
				component.Type = SkillTargetingData.TargetingType.Simple
			"ShapedFree":
				component.Type = SkillTargetingData.TargetingType.ShapedFree
			"ShapedDirectional":
				component.Type = SkillTargetingData.TargetingType.ShapedDirectional
			"SelfOnly":
				component.Type = SkillTargetingData.TargetingType.SelfOnly
			"Global":
				component.Type = SkillTargetingData.TargetingType.Global

	if _data.has("ShapedPrefab"):
		var shape_as_string = _data["ShapedPrefab"]
		if !shape_as_string.is_empty():
			var index = shapedPrefabNameArray.find(shape_as_string)
			if index != -1:
				var shape = ResourceLoader.load(shapedPrefabPathArray[index]) as TargetingShapeBase
				component.shapedTiles = shape

	pass
