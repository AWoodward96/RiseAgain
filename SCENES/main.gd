extends Node2D
class_name Main

static var Root : Main

@export var DEBUG_Campaign : PackedScene
@export var DEBUG_AutoEnter : bool

@export var BastionParent : Node2D
@export var CampaignParent : Node2D

var currentBastion : Bastion

func _ready():
	Root = self
	if DEBUG_Campaign != null && DEBUG_AutoEnter:
		var campaign = DEBUG_Campaign.instantiate() as Campaign
		if campaign != null:
			GameManager.StartCampaign(CampaignInitData.Construct(campaign, []))
