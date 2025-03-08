extends Node2D

static var CurrentCampaign : Campaign

@export var GameSettings : GameSettingsTemplate
@export var UnitSettings : UnitSettingsTemplate
@export var LocalizationSettings : LocSettings

@export var TutorialCutscene : CutsceneTemplate
@export var LoadingScreenPrefab : PackedScene

var CurrentGameState : GameState
var loadingScreen : LoadingScreen
var csrUI : CSR
var persistInitialized : bool
var cutsceneInitialized : bool

func _ready() -> void:
	PersistDataManager.Initialized.connect(PersistDataManagerFinished)
	CutsceneManager.Initialized.connect(CutsceneManagerFinished)
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

func PersistDataManagerFinished():
	persistInitialized = true
	CheckInitFinished()

func CutsceneManagerFinished():
	cutsceneInitialized = true
	CheckInitFinished()

func CheckInitFinished():
	if persistInitialized && cutsceneInitialized:
		OnInitFinished()


func OnInitFinished():
	if RunningMainScene():
		#if CutsceneManager.active_cutscene == null:
		# Check if there is a campaign in the save data
		var campaign = PersistDataManager.TryLoadCampaign() as Campaign
		if campaign != null:
			# we need to figure out what to do here
			StartCampaign(campaign)
		else:
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

func RunningMainScene():
	return get_tree().get_first_node_in_group("MainScene") != null

func StartCampaign(_campaign : Campaign):
	ChangeGameState(CampaignGameState.new(), _campaign)
