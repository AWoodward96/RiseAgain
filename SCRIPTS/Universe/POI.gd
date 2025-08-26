@tool
extends Control
class_name POI

enum POI_VisualStyle {
	CombatMap = 7,
	Event = 11,
	Campsite = 19,
	Town = 5,
	Navigation = 21 }

@export var loc_title : String
@export var loc_description : String
@export var internal_name : String
@export var requirements : Array[RequirementBase] = []

@export var Maps : MapBlock
@export var VisualStyle : POI_VisualStyle = POI_VisualStyle.CombatMap
@export var VisualIcon : Sprite2D

@export_category("Starting Information")
@export var StartingNode : bool = false
@export var StartingNodeUnlockCondition : Array[RequirementBase]

@export_category("Neighbors")

@export var AdjacentPOIs : Array[POIAdjacencyData]

@export_category("Line Data")

@export var LineDotted : Texture2D
@export var LineTiny : Texture2D
@export var LineFull : Texture2D
@export var DefaultLineColor : Color = Color.WHITE
@export var TraversedLineColor : Color = Color.DARK_CYAN


var selected = false
var selectable = false



func _process(delta):
	if Engine.is_editor_hint():
		AdjacentPOIs.clear()
		var children = get_children()
		for child in children:
			if child is POIAdjacencyData:
				AdjacentPOIs.append(child as POIAdjacencyData)

	if VisualIcon != null:
		if !selected:
			VisualIcon.frame = VisualStyle
		else:
			VisualIcon.frame = VisualStyle + 1

func Refresh():
	for adjacency in AdjacentPOIs:
		if !adjacency.PassesRequirement() || adjacency.Neighbor == null:
			continue

		var traversed = false
		if GameManager.CurrentCampaign != null:
			traversed = GameManager.CurrentCampaign.campaignLedger.has(adjacency.Neighbor.internal_name)


		UpdateLine(adjacency, traversed)
	pass

func UpdateLine(_neighborData : POIAdjacencyData, _traversed : bool):
	if _neighborData == null:
		return

	if !_neighborData.Traversable:
		_neighborData.visible = false
		return

	if _traversed:
		_neighborData.texture = LineFull
		_neighborData.default_color = TraversedLineColor
	else:
		_neighborData.default_color = DefaultLineColor
		_neighborData.texture = LineDotted

	_neighborData.visible = true
	_neighborData.texture_mode = Line2D.LINE_TEXTURE_TILE

	_neighborData.clear_points()
	_neighborData.add_point(Vector2.ZERO)
	var dst = _neighborData.Neighbor.global_position - global_position
	_neighborData.add_point(dst)
