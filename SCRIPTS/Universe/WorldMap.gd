extends FullscreenUI

enum WorldMapUIState { NewCampaign, NextMap, Browsing }

signal POISelected(_poi : POI)

@export var offset : Control
@export var lerpSpeed : float = 4

@export_category("Hover Panel")
@export var HoverPanelParent : Control
@export var HoverPanelTitleLabel : RichTextLabel
@export var HoverPanelDescLabel : RichTextLabel
@export var HoverPanelOffset : Vector2i = Vector2(20, -20)

var allPOIS : Array[POI]
var startingPOIs : Array[POI]
var currentCampaign : Campaign
var currentlySelectedPOI : POI

var state : WorldMapUIState = WorldMapUIState.Browsing
var fullscreenHelperUI : CanvasLayer

func _ready() -> void:
	BuildPOIArray()
	visible = false


func Open(_uiState : WorldMapUIState):
	visible = true
	currentCampaign = GameManager.CurrentCampaign
	state = _uiState

	match _uiState:
		WorldMapUIState.NewCampaign:
			InitNewCampaign()
			pass
		WorldMapUIState.NextMap:
			InitNextMapSelection()
			pass
		WorldMapUIState.Browsing:
			InitBrowsing()
			pass


func InitNewCampaign():
	HoverStartingPOI()
	RefreshAllPOIs()
	pass

func InitBrowsing():
	pass

func InitNextMapSelection():
	# Get the current campaign
	HoverCurrentMapPOI()
	RefreshAllPOIs()
	UpdateForTraversal()
	pass

func UpdateForTraversal():
	if currentCampaign == null:
		return

	for poi in allPOIS:
		if poi != null:
			poi.selectable = false


	var adjacentPOIs = currentCampaign.currentPOI.AdjacentPOIs
	for adjacencyData : POIAdjacencyData in adjacentPOIs:
		if adjacencyData == null:
			continue

		if !adjacencyData.Traversable:
			continue

		if adjacencyData.Neighbor != null:
			for ledgerEntry in currentCampaign.campaignLedger:
				if ledgerEntry == adjacencyData.Neighbor.internal_name:
					continue

			if !adjacencyData.PassesRequirement():
				continue

			adjacencyData.Neighbor.selectable = true
		else:
			var parent = adjacencyData.get_parent()
			push_error("Adjacency: ", adjacencyData.name ," - child of ", parent.name, " doesn't have a neighbor. Fix")


func BuildPOIArray():
	allPOIS.clear()
	startingPOIs.clear()
	var allChildren = get_tree().get_nodes_in_group("MapPOI")
	for child in allChildren:
		if child != null && child is POI:
			allPOIS.append(child)
			if child.StartingNode:
				startingPOIs.append(child)

func _process(_delta: float):
	if !visible:
		return

	UpdateInputNavigation()
	UpdateHoveredPOICenter(_delta)
	UpdateHoveredPOIPanelPosition()

func UpdateInputNavigation():
	if currentlySelectedPOI != null:
		if InputManager.inputDown[0]:
			var upNeighbor = GetNavigationOptionFromPOI(currentlySelectedPOI, GameSettingsTemplate.Direction.Up)
			if upNeighbor != null:
				HoverPOI(upNeighbor, false)

		if InputManager.inputDown[1]:
			var rightNeighbor = GetNavigationOptionFromPOI(currentlySelectedPOI, GameSettingsTemplate.Direction.Right)
			if rightNeighbor != null:
				HoverPOI(rightNeighbor, false)

		if InputManager.inputDown[2]:
			var downNeighbor = GetNavigationOptionFromPOI(currentlySelectedPOI, GameSettingsTemplate.Direction.Down)
			if downNeighbor != null:
				HoverPOI(downNeighbor, false)

		if InputManager.inputDown[3]:
			var leftNeighbor = GetNavigationOptionFromPOI(currentlySelectedPOI, GameSettingsTemplate.Direction.Left)
			if leftNeighbor != null:
				HoverPOI(leftNeighbor, false)

	if InputManager.selectDown:
		SelectPOI(currentlySelectedPOI)

func GetNavigationOptionFromPOI(_poi : POI, _dir : GameSettingsTemplate.Direction):
	if _poi == null:
		return null

	for adj : POIAdjacencyData in _poi.AdjacentPOIs:
		if adj.Direction == _dir && adj.PassesRequirement():
			return adj.Neighbor
	return null

func UpdateHoveredPOICenter(_delta, snap : bool = false):
	if currentlySelectedPOI == null:
		return

	var hoveredPOIsPosition = currentlySelectedPOI.global_position
	# get the poi's position relative to the offset
	var offsetDST = hoveredPOIsPosition - offset.global_position

	# get the half-extents of this elements size (can be the screen size, can be an element's size that's being clipped by a parent control
	var halfExtents = size / 2
	# desired position is the halfextents, minus the offset and minus the size of the poi element (should be around (12,12) but w/e, dynamic.)
	var desiredPosition =  halfExtents - offsetDST - (currentlySelectedPOI.size / 2)

	if !snap:
		offset.position = lerp(offset.position, desiredPosition, _delta * lerpSpeed)
	else:
		offset.position = desiredPosition

func UpdateHoveredPOIPanelPosition():
	if currentlySelectedPOI == null:
		return

	HoverPanelParent.global_position = Vector2i(currentlySelectedPOI.global_position) - Vector2i(0, HoverPanelParent.size.y) + HoverPanelOffset

func UpdatePOIPanelText():
	if currentlySelectedPOI == null:
		return

	HoverPanelTitleLabel.text = currentlySelectedPOI.loc_title
	HoverPanelDescLabel.text = currentlySelectedPOI.loc_description

func RefreshAllPOIs():
	for poi in allPOIS:
		if poi != null:
			poi.Refresh()

func HoverPOI(_poi : POI, _snapTo : bool):
	if currentlySelectedPOI != null:
		currentlySelectedPOI.selected = false

	currentlySelectedPOI = _poi
	currentlySelectedPOI.selected = true

	if _snapTo:
		UpdateHoveredPOICenter(0, true)
	UpdatePOIPanelText()

func HoverCurrentMapPOI():
	if GameManager.CurrentCampaign.currentPOI != null:
		HoverPOI(currentCampaign.currentPOI, true)

	pass

func HoverStartingPOI():
	if startingPOIs.size() > 0:
		if startingPOIs.size() == 1:
			# Select the first one, and don't show the starting point selection screen
			HoverPOI(startingPOIs[0], true)

			GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(startingPOIs[0], []))
			# immediately skip to the campaign selection
		else:
			ShowStartingPointSelection()
	else:
		push_error("WORLD_MAP_UI: No Starting POIs found.")
		return


func SelectPOI(_poi : POI):
	if _poi.selectable:
		POISelected.emit(_poi)
	pass

func ShowStartingPointSelection():
	HoverPOI(startingPOIs[0], true)

func GetPOIFromID(_poiID : String):
	for pois in allPOIS:
		if pois.internal_name == _poiID:
			return pois

	push_error("Could not find POI: " + _poiID)
	return null


func OpenWorldMapFullscreenUI(_worldMapState : WorldMapUIState):
	if fullscreenHelperUI != null:
		return

	UIManager.OnUIOpened(self)
	Open(_worldMapState)

func CloseUI():
	reparent(get_tree().root)
	visible = false
