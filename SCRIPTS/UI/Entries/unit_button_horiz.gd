extends Button

func Initialize(_unit : UnitInstance):
	if _unit == null || _unit.Template == null:
		return
	icon = _unit.Template.icon
	text = _unit.Template.loc_DisplayName
