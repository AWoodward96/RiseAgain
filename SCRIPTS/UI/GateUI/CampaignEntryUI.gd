extends Control
class_name CampaignEntryUI

signal CampaignSelected(_campaignTemplate : CampaignTemplate)

@export var CampaignIcon : TextureRect
@export var CampaignNameText : Label
@export var EmptySlotColor : Color
@export var SlotsParent : Control

var myCampaign : CampaignTemplate

func Initialize(_campaign : CampaignTemplate):
	if _campaign == null:
		queue_free()
		return
	myCampaign = _campaign
	CampaignIcon.texture = _campaign.loc_icon
	CampaignNameText.text = _campaign.loc_name

	for i in range(0, _campaign.startingRosterSize):
		if _campaign.requiredUnit.size() > 0 && i < _campaign.requiredUnit.size():
			var textRect = TextureRect.new()
			textRect.custom_minimum_size = Vector2(32, 32)
			textRect.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
			textRect.texture = _campaign.requiredUnit[i].icon
			SlotsParent.add_child(textRect)
		else:
			var colorRect = ColorRect.new()
			colorRect.custom_minimum_size = Vector2(32, 32)
			colorRect.color = EmptySlotColor
			SlotsParent.add_child(colorRect)
		pass
	pass

func Pressed():
	CampaignSelected.emit(myCampaign)
