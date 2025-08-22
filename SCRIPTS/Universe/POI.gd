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

@export var Maps : MapBlock
@export var VisualStyle : POI_VisualStyle = POI_VisualStyle.CombatMap
@export var VisualIcon : Sprite2D

@export_category("Starting Information")
@export var StartingNode : bool = false
@export var StartingNodeUnlockCondition : Array[RequirementBase]

@export_category("Neighbors")

@export var Up : POI
@export var Right : POI
@export var Down : POI
@export var Left : POI

@export_category("Lines")
@export var UpLine : Line2D
@export var RightLine : Line2D
@export var DownLine : Line2D
@export var LeftLine : Line2D

var selected = false


func _process(delta):
	UpdateLine(UpLine, Up)
	UpdateLine(RightLine, Right)
	UpdateLine(DownLine, Down)
	UpdateLine(LeftLine, Left)

	if VisualIcon != null:
		if !selected:
			VisualIcon.frame = VisualStyle
		else:
			VisualIcon.frame = VisualStyle + 1


func UpdateLine(_line2d : Line2D, _neighbor : POI):
	if _line2d == null:
		return

	if _neighbor == null:
		_line2d.visible = false
		return

	_line2d.visible = true

	_line2d.clear_points()
	_line2d.add_point(Vector2.ZERO)
	var dst = _neighbor.global_position - global_position
	_line2d.add_point(dst)
