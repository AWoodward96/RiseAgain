extends Node2D

static var CurrentCampaign : CampaignTemplate

@export var GameSettings : GameSettingsTemplate
@export var UnitSettings : UnitSettingsTemplate
@export var LocalizationSettings : LocSettings
@export var AlphaUnitSelection : PackedScene
@export var AlphaFormationUI : PackedScene
@export var CombatHUDUI : PackedScene
@export var MapRewardUI : PackedScene
@export var ExperienceUI : PackedScene
@export var AbilitySelectionUI : PackedScene
@export var UnitInspectionUI : PackedScene
@export var CSRUI : PackedScene
@export var CampsiteUIPrefab : PackedScene

@export var LoadingScreenPrefab : PackedScene

var loadingScreen : LoadingScreen
var csrUI : CSR

func _process(_delta: float):
	if Input.is_action_just_pressed("cheat"):
		if csrUI != null:
			remove_child(csrUI)
			csrUI.queue_free()
			csrUI = null
		else:
			csrUI = CSR.ShowMenu()

	pass

func CreateLoadingScreen():
	loadingScreen = LoadingScreenPrefab.instantiate() as LoadingScreen
	add_child(loadingScreen)

func ShowLoadingScreen(_fadeTime = 1.5, lambda = null):
	if loadingScreen == null:
		CreateLoadingScreen()

	loadingScreen.ShowLoadingScreen(_fadeTime, lambda)
	return loadingScreen.ObscureComplete

func HideLoadingScreen(_fadeTime = 1.5, lambda = null):
	if loadingScreen == null:
		CreateLoadingScreen()

	loadingScreen.HideLoadingScreen(_fadeTime, lambda)
	return loadingScreen.ClearComplete
