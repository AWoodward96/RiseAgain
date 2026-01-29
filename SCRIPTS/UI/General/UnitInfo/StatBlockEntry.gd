extends InspectableElement
class_name StatBlockEntry

@export var icon : TextureRect
@export var statName : Label
@export var statValue : Label
@export var statIncreaseLabel : Label
@export var detailElement : DetailEntry

func Refresh(_stat : StatTemplate, _val : int, _useShorthand : bool = true, _increase : int = 0):
	if icon != null: icon.texture = _stat.loc_icon
	if statName != null :
		if _useShorthand:
			statName.text = _stat.loc_displayName_short
		else:
			statName.text = _stat.loc_displayName

	if statValue != null: statValue.text = "%01.0d" % _val
	if statIncreaseLabel != null:
		statIncreaseLabel.visible = _increase > 0
		statIncreaseLabel.text = "+%01.0d" % _increase

	if detailElement != null:
		detailElement.tooltip = _stat.loc_description

	pass
