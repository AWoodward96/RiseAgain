extends CanvasLayer
class_name CombatHUD

signal TurnStartAnimComplete

@export var AllyTurnBanner : PackedScene
@export var EnemyTurnBanner : PackedScene
@export var NeutralTurnBanner : PackedScene
@export var InspectUI : InspectPanel
@export var ContextUI : ContextMenu
@export var NoTargets : Control

@onready var center_left_anchor = $CenterLeft
@onready var top_left_anchor = $TopLeft
@onready var top_right_anchor = $TopRight

var map

func _ready():
	ContextUI.visible = false
	NoTargets.visible = false

func Initialize(_map : Map, _currentTile : Tile):
	map = _map
	map.playercontroller.OnTileChanged.connect(OnTileChanged)
	OnTileChanged(_currentTile)
	ContextUI.ActionSelected.connect(OnAbilitySelected)

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

	TurnStartAnimComplete.emit()

func OnTileChanged(_tile : Tile):
	if _tile != null && _tile.Occupant != null:
		InspectUI.visible = true
		InspectUI.Update(_tile.Occupant)
	else:
		InspectUI.set_visible(false)

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
