extends Node2D

@export var GameSettings : GameSettings
@export var UnitSettings : UnitSettings
@export var AlphaUnitSelection : PackedScene
@export var AlphaFormationUI : PackedScene
@export var CombatHUDUI : PackedScene
@export var UnitInventoryUI : PackedScene
@export var MapRewardUI : PackedScene

@export var LoadingScreenPrefab : PackedScene

var loadingScreen : LoadingScreen

func _ready():
	return

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
