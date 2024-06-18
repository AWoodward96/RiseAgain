extends CanvasLayer
class_name CombatHUD

signal BannerAnimComplete

@export var AllyTurnBanner : PackedScene
@export var EnemyTurnBanner : PackedScene
@export var NeutralTurnBanner : PackedScene
@export var VictoryBanner : PackedScene
@export var InspectUI : InspectPanel
@export var ContextUI : ContextMenu
@export var DmgPreviewUI : DamagePreviewUI
@export var itemSelectUI : ItemSelectionUI
@export var NoTargets : Control

@export_category("Anchors")
@onready var center_left_anchor = $CenterLeft
@onready var top_left_anchor = $TopLeft
@onready var top_right_anchor = $TopRight
@export var bottom_left_anchor : Control
@export var bottom_right_anchor : Control


var map
var ctrl : PlayerController
var reticleSide = true # defaults to true, because that's where it's actually starting - on the left side

func _ready():
	ContextUI.visible = false
	NoTargets.visible = false
	itemSelectUI.visible = false

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
	ContextUI.Initialize()
	pass

func HideContext():
	ContextUI.visible = false

func OnAnyActionSelected():
	HideContext()

func ShowNoTargets(_show : bool):
	NoTargets.visible = _show

func ShowItemSelectionUI(_unit : UnitInstance, _inventoryFilter):
	itemSelectUI.visible = true
	itemSelectUI.Initialize(_unit, _inventoryFilter)

func ClearItemSelectionUI():
	itemSelectUI.visible = false

func ShowDamagePreviewUI(_attacker : UnitInstance, _weapon : Item, _defender : UnitInstance):
	DmgPreviewUI.visible = true
	DmgPreviewUI.ShowPreviewDamage(_attacker, _weapon, _defender)

func ClearDamagePreviewUI():
	DmgPreviewUI.visible = false

func UpdateInspectUISide():
	# update the InspectUI based on where the reticle is so that it's not in the way
	var newside = ctrl.IsReticleInLeftHalfOfViewport()
	if newside != reticleSide:
		InspectUI.get_parent().remove_child(InspectUI)
		DmgPreviewUI.get_parent().remove_child(DmgPreviewUI)

		# If side is true, the Reticle is on the left side of the screen, so to help visibility, the UI should be moved to the RIGHT
		if reticleSide:
			bottom_left_anchor.add_child(InspectUI)
			InspectUI.position = Vector2(0, -InspectUI.size.y)

			top_left_anchor.add_child(DmgPreviewUI)
		else:
			# If side is false, the Reticle is on the right side of the screen, so to help visibility, the UI should be move to the LEFT
			bottom_right_anchor.add_child(InspectUI)
			InspectUI.position = Vector2(-InspectUI.size.x, -InspectUI.size.y)

			top_right_anchor.add_child(DmgPreviewUI)

	reticleSide = newside

func OnTileChanged(_tile : Tile):
	UpdateInspectUISide()
	pass
