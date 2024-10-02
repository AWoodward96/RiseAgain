extends CanvasLayer
class_name CSR

static var AllAbilitiesCost0 : bool = false


func btnAllAbilitiesCost0():
	AllAbilitiesCost0 = !AllAbilitiesCost0

func btnUnlockAllAbilities():
	var map = Map.Current
	if map == null:
		return

	var allAllies = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	for unit in allAllies:
		if unit == null:
			continue

		var template = unit.Template as UnitTemplate
		if template == null:
			continue

		for ability in template.Tier1Abilities:
			unit.AddAbility(ability)
	pass


static func ShowMenu():
	var csrMenu = GameManager.CSRUI.instantiate() as CSR
	GameManager.add_child(csrMenu)
	return csrMenu
