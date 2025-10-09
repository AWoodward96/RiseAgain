extends Control
class_name RouteEntry

# DELETE

@export var EntrySelectionBG : ColorRect
@export var RouteLabel : Label
@export var RouteIcon : TextureRect

var gate : Gate
var template : CampaignTemplate

func Initialize(_gate : Gate, _template : CampaignTemplate):
	gate = _gate
	template = _template
	RouteLabel.text = _template.loc_name
	RouteIcon.texture = _template.loc_icon
	pass


func _process(_delta: float) -> void:
	if EntrySelectionBG.visible && InputManager.selectDown:
		OnPressed()

func OnFocus() -> void:
	EntrySelectionBG.visible = true
	pass # Replace with function body.


func OnUnFocus() -> void:
	EntrySelectionBG.visible = false
	pass # Replace with function body.


func OnPressed() -> void:
	gate.CampaignSelected(template)
	pass # Replace with function body.
