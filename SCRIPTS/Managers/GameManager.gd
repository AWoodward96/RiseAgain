extends Node2D

static var CurrentCampaign : CampaignTemplate

@export var GameSettings : GameSettingsTemplate
@export var UnitSettings : UnitSettingsTemplate
@export var LocalizationSettings : LocSettings


@export var LoadingScreenPrefab : PackedScene

var CurrentGameState : GameState
var loadingScreen : LoadingScreen
var csrUI : CSR

func _ready() -> void:
	PersistDataManager.Initialized.connect(OnInitFinished)
	pass

func _process(_delta: float):
	if CurrentGameState != null:
		CurrentGameState.Update(_delta)

	if Input.is_action_just_pressed("cheat"):
		if csrUI != null:
			remove_child(csrUI)
			csrUI.queue_free()
			csrUI = null
			CSR.Open = false
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
	return loadingScreen

func HideLoadingScreen(_fadeTime = 1.5, lambda = null):
	if loadingScreen == null:
		CreateLoadingScreen()

	loadingScreen.HideLoadingScreen(_fadeTime, lambda)
	return loadingScreen

func OnInitFinished():
	if get_tree().root == Main.Root:
		ReturnToBastion()
	pass

func ReturnToBastion():
	ChangeGameState(BastionGameState.new(), null)
	pass

func ChangeGameState(_newGamestate : GameState, _initData):
	if CurrentGameState != null:
		CurrentGameState.Exit()

	CurrentGameState = _newGamestate
	CurrentGameState.Enter(_initData)

func StartCampaign(_campaignInitData : CampaignInitData):
	ChangeGameState(CampaignGameState.new(), _campaignInitData)
