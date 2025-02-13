extends CanvasLayer
class_name CombatHUD

signal BannerAnimComplete

@export var AllyTurnBanner : PackedScene
@export var EnemyTurnBanner : PackedScene
@export var NeutralTurnBanner : PackedScene
@export var VictoryBanner : PackedScene
@export var LossBanner : PackedScene
@export var InspectUI : InspectPanel
@export var InspectEffectsUI : GridEntryList
@export var ContextUI : ContextMenu
@export var DmgPreviewUI : DamagePreviewUI
@export var NoTargets : Control
@export var TerrainInspectUI : TerrainInspectPanel

@export_category("Objectives")
@export var ObjectivesParent : Control
@export var ObjectiveText : Label
@export var OptionalObjectiveParent : Control
@export var OptionalObjectiveText : Label

@export_category("Anchors")
@onready var center_left_anchor = $CenterLeft
@onready var top_left_anchor = $TopLeft
@onready var top_right_anchor = $TopRight
@export var bottom_left_anchor : Control
@export var bottom_right_anchor : Control


var map : Map
var ctrl : PlayerController
var lastReticleSide = -1 	# -1 : The reticle is unknown and needs to be updated
							#  0 : The reticle is on the right side, so the UI should be on the left
							#  1 : The reticle is on the left side, so the UI should be on the right

func _ready():
	ContextUI.visible = false
	NoTargets.visible = false

func Initialize(_map : Map, _currentTile : Tile):
	await self.ready

	map = _map
	ctrl = map.playercontroller

	InspectUI.Initialize(_map.playercontroller)

	# Bind those ContextUI signals
	ContextUI.OnAnyActionSelected.connect(OnAnyActionSelected)
	ctrl.OnTileChanged.connect(OnTileChanged)

	# Do this now that we have a map ref
	UpdateInspectUISide()
	UpdateObjectives()

func PlayTurnStart(_allegiance : GameSettingsTemplate.TeamID):
	var scene
	match _allegiance:
		GameSettingsTemplate.TeamID.ALLY:
			scene = AllyTurnBanner
		GameSettingsTemplate.TeamID.ENEMY:
			scene = EnemyTurnBanner
		GameSettingsTemplate.TeamID.NEUTRAL:
			scene = NeutralTurnBanner

	var createdElement = scene.instantiate()
	center_left_anchor.add_child(createdElement)
	await createdElement.AnimationComplete

	UpdateObjectives()
	BannerAnimComplete.emit()

func PlayVictoryBanner():
	var createdElement = VictoryBanner.instantiate()
	center_left_anchor.add_child(createdElement)
	await createdElement.AnimationComplete

	BannerAnimComplete.emit()

func PlayLossBanner():
	var createdElement = LossBanner.instantiate()
	center_left_anchor.add_child(createdElement)
	await createdElement.AnimationComplete

	BannerAnimComplete.emit()

func HideInspectUI():
	InspectUI.visible = false

func ShowContext():
	ContextUI.visible = true
	ContextUI.global_position = top_right_anchor.global_position
	ContextUI.Initialize()
	pass

func HideContext():
	ContextUI.visible = false

func OnAnyActionSelected():
	HideContext()

func ShowNoTargets(_show : bool):
	NoTargets.visible = _show

func ShowDamagePreviewUI(_attacker : UnitInstance, _weapon : UnitUsable, _defender : UnitInstance, _targetData : TileTargetedData):
	DmgPreviewUI.visible = true
	DmgPreviewUI.ShowPreviewDamage(_attacker, _weapon, _defender, _targetData)

func ClearDamagePreviewUI():
	DmgPreviewUI.visible = false

func UpdateInspectUISide():
	# update the InspectUI based on where the reticle is so that it's not in the way
	var side = ctrl.IsReticleInLeftHalfOfViewport()
	var newside = (side if 1 else 0) as int
	if newside == 1:
		InspectUI.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)

		if InspectUI.visible:
			TerrainInspectUI.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		else:
			TerrainInspectUI.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)

	elif newside == 0:
		InspectUI.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		if InspectUI.visible:
			TerrainInspectUI.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		else:
			TerrainInspectUI.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)

	lastReticleSide = newside

func UpdateObjectives():
	ObjectiveText.text = map.WinCondition.UpdateLocalization(map)
	if map.OptionalObjectives.size() > 0:
		OptionalObjectiveParent.visible = true

		# For now only do the first one
		var firstOptional = map.OptionalObjectives[0]
		OptionalObjectiveText.text = firstOptional.UpdateLocalization(map)
	else:
		OptionalObjectiveParent.visible = false
	pass


func OnTileChanged(_tile : Tile):
	if _tile.Occupant == null:
		HideInspectUI()
	else:
		InspectUI.visible = true

	TerrainInspectUI.Update(_tile)
	UpdateInspectUISide()
	pass
