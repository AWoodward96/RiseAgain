extends Control
class_name WorldMap

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


func _ready() -> void:
	currentCampaign = GameManager.CurrentCampaign
	BuildPOIArray()

	# If current Campaign is null, we're starting a new campaign
	if currentCampaign == null:
		InitNewCampaign()
	else:
		# Alternatively, I could try Map.Current == null, and see if it works
		if Map.Current.MapState is VictoryState:
			InitMapComplete()
		else:
			InitBrowsing()
	# If currentCampaign is not null then we're continuing a campaign.
	# If the current map is not complete, we're just browsing, if the current map is complete, then we need to select where we're going next
	pass

func InitNewCampaign():
	HoverStartingPOI()
	pass

func InitBrowsing():
	pass

func InitMapComplete():
	pass

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
	UpdateInputNavigation()
	UpdateHoveredPOICenter(_delta)
	UpdateHoveredPOIPanelPosition()

func UpdateInputNavigation():
	if currentlySelectedPOI != null:
		if InputManager.inputDown[0]:
			if currentlySelectedPOI.Up != null:
				HoverPOI(currentlySelectedPOI.Up, false)

		if InputManager.inputDown[1]:
			if currentlySelectedPOI.Right != null:
				HoverPOI(currentlySelectedPOI.Right, false)

		if InputManager.inputDown[2]:
			if currentlySelectedPOI.Down != null:
				HoverPOI(currentlySelectedPOI.Down, false)


		if InputManager.inputDown[3]:
			if currentlySelectedPOI.Left != null:
				HoverPOI(currentlySelectedPOI.Left, false)

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

func HoverPOI(_poi : POI, _snapTo : bool):
	if currentlySelectedPOI != null:
		currentlySelectedPOI.selected = false

	currentlySelectedPOI = _poi
	currentlySelectedPOI.selected = true

	if _snapTo:
		UpdateHoveredPOICenter(0, true)
	UpdatePOIPanelText()

func HoverCurrentMapPOI():
	pass

func HoverStartingPOI():
	if startingPOIs.size() > 0:
		if startingPOIs.size() == 1:
			# Select the first one, and don't show the starting point selection screen
			HoverPOI(startingPOIs[0], true)
		else:
			ShowStartingPointSelection()
	else:
		push_error("WORLD_MAP_UI: No Starting POIs found.")
		return


func ShowStartingPointSelection():
	HoverPOI(startingPOIs[0], true)


static func ShowWorldMap():
	var instance = UIManager.WorldMapUI.instantiate()
	GameManager.get_tree().root.add_child(instance)
	return instance
