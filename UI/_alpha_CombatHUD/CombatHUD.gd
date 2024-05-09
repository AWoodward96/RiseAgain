extends CanvasLayer
class_name CombatHUD

signal BannerAnimComplete

@export var AllyTurnBanner : PackedScene
@export var EnemyTurnBanner : PackedScene
@export var NeutralTurnBanner : PackedScene
@export var VictoryBanner : PackedScene
@export var InspectUI : InspectPanel
@export var ContextUI : ContextMenu
@export var NoTargets : Control

@onready var center_left_anchor = $CenterLeft
@onready var top_left_anchor = $TopLeft
@onready var top_right_anchor = $TopRight

var map
var ctrl : PlayerController

func _ready():
	ContextUI.visible = false
	NoTargets.visible = false

func Initialize(_map : Map, _currentTile : Tile):
	map = _map
	InspectUI.Initialize(_map.playercontroller)
	ContextUI.ActionSelected.connect(OnAbilitySelected)
	ctrl = map.playercontroller

func PlayTurnStart(_allegiance : GameSettings.TeamID):
	var scene
	match _allegiance:
		GameSettings.TeamID.ALLY:
			scene = AllyTurnBanner
		GameSettings.TeamID.ENEMY:
			scene = EnemyTurnBanner
		GameSettings.TeamID.NEUTRAL:
			scene = NeutralTurnBanner

	var createdElement = scene.instantiate()
	center_left_anchor.add_child(createdElement)

	await createdElement.AnimationComplete

	BannerAnimComplete.emit()

func PlayVictoryBanner():
	var createdElement = VictoryBanner.instantiate()
	center_left_anchor.add_child(createdElement)
	await createdElement.AnimationComplete

	BannerAnimComplete.emit()

func HideInspectUI():
	InspectUI.visible = false

func ShowContext(_unit : UnitInstance):
	ContextUI.visible = true
	ContextUI.global_position = top_right_anchor.global_position
	ContextUI.Initialize(_unit)
	pass

func HideContext():
	ContextUI.Clear()
	ContextUI.visible = false

func OnAbilitySelected(_ability : AbilityInstance):
	HideContext()

func ShowNoTargets(_show : bool):
	NoTargets.visible = _show
