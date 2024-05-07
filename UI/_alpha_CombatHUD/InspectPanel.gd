extends Control
class_name InspectPanel

@export var icon : TextureRect
@export var healthbar : ProgressBar
@export var healthText : Label
@export var namelabel : Label

func Update(_unit : UnitInstance):
	if _unit == null || _unit.Template == null:
		return

	var template = _unit.Template
	namelabel.text = template.loc_DisplayName
	icon.texture = template.icon
	healthText.text = str(_unit.currentHealth) + "/" + str(_unit.maxHealth)
	healthbar.value = _unit.currentHealth / _unit.maxHealth
