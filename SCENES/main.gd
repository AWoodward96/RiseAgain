extends Node2D

@export var DEBUG_Campaign : PackedScene

func _ready():
	if DEBUG_Campaign != null:
		var campaign = DEBUG_Campaign.instantiate() as CampaignTemplate
		if campaign != null:
			GameManager.CurrentCampaign = campaign
			add_child(campaign)
			campaign.StartCampaign([])
