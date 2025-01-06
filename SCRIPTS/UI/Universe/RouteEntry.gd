extends Control
class_name RouteEntry


@export var EntrySelectionBG : ColorRect
@export var RouteLabel : Label
@export var RouteIcon : TextureRect

var gate : Gate
var template : CampaignTemplate

func Initialize(_gate : Gate, _campaignTemplate : CampaignTemplate):
	gate = _gate
	template = _campaignTemplate
	RouteLabel.text = _campaignTemplate.loc_name
	RouteIcon.texture = _campaignTemplate.loc_icon
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
