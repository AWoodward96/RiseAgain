extends FullscreenUI
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
@export var ObjectivePanelUI : ObjectivePanel
@export var TutorialPrompt : TutorialPromptPanel


@export_category("Anchors")
@export var center_left_anchor : Control
@export var top_right_anchor : Control
@export var AvailableUIAnchors : Array[Control.LayoutPreset]
@export var BlankAnchor : AnchoredUIElement
@export var PresetAnchoredUIElements : Array[AnchoredUIElement]

@export_category("SFX")
@export var TurnStartSound : FmodEventEmitter2D

var map : Map
var ctrl : PlayerController
var lastReticleSide = -1 	# -1 : The reticle is unknown and needs to be updated
							#  0 : The reticle is on the right side, so the UI should be on the left
							#  1 : The reticle is on the left side, so the UI should be on the right
var currentAnchoredUIElements : Array[AnchoredUIElement]

func _ready():
	ContextUI.visible = false
	NoTargets.visible = false
	currentAnchoredUIElements.clear()
	for preset in PresetAnchoredUIElements:
		currentAnchoredUIElements.append(preset)

func Initialize(_map : Map, _currentTile : Tile):
	#await self.ready

	map = _map
	ctrl = map.playercontroller

	InspectUI.Initialize(_map.playercontroller)

	# Bind those ContextUI signals
	ContextUI.OnAnyActionSelected.connect(OnAnyActionSelected)
	ctrl.OnTileChanged.connect(OnTileChanged)

	# This is bullshit - but wait two frames lmao
	# The anchored UI elements need the player-controllers desired camera position --
	# -- and that is waiting for the viewport to be initialized
	# -- so basically wait two frames
	await get_tree().process_frame
	await get_tree().process_frame

	# Do this now that we have a map ref
	TerrainInspectUI.Update(ctrl.CurrentTile)
	UpdateAnchoredUIElements()
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

	if TurnStartSound != null:
		TurnStartSound.play()

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
	InspectUI.Disabled = true

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

func ShowTutorialPrompt(_text : String, _anchor : Control.LayoutPreset):
	TutorialPrompt.Disabled = false
	TutorialPrompt.PromptLabel.text = _text
	TutorialPrompt.RefreshAnchor([_anchor])

func HideTutorialPrompt():
	TutorialPrompt.Disabled = true

func UpdateAnchoredUIElements():
	# update the InspectUI based on where the reticle is so that it's not in the way
	ctrl.UpdateReticleQuintant()
	var side = ctrl.ReticleQuintet

	var availableQuadrants = AvailableUIAnchors.duplicate()
	# put the blank anchor where the reticle currently is
	var index = availableQuadrants.find(side)
	if index != -1:
		availableQuadrants.remove_at(index)
	BlankAnchor.RefreshAnchor([side])

	# Also make sure the  blank anchor isn't in the current anchors
	var remainingElements = currentAnchoredUIElements.duplicate()
	var blankIndex = remainingElements.find(BlankAnchor)
	if blankIndex != -1:
		remainingElements.remove_at(blankIndex)

	# This sorts high priority items to the start of the list
	remainingElements.sort_custom(func(a, b): return a.Priority > b.Priority)
	for element in remainingElements:
		var slot = element.RefreshAnchor(availableQuadrants)
		if slot != null:
			var slotIndex = availableQuadrants.find(slot)
			availableQuadrants.remove_at(slotIndex)


func UpdateObjectives():
	ObjectivePanelUI.RefreshObjective(map)
	pass


func OnTileChanged(_tile : Tile):
	if _tile.Occupant == null || (_tile.Occupant != null && _tile.Occupant.ShroudedFromPlayer):
		HideInspectUI()
	else:
		InspectUI.Disabled = false

	TerrainInspectUI.Update(_tile)
	UpdateAnchoredUIElements()
	pass
