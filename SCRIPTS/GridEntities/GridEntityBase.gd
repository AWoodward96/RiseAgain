extends Node2D
class_name GridEntityBase

@export var UpdatePerTeamTurn : bool
@export var UpdatePerUnitTurn : bool

var Origin : Tile
var Allegience : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ENEMY
var Source : UnitInstance
var CurrentMap : Map
var Expired : bool = false
var ExecutionComplete : bool = false

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _allegience : GameSettingsTemplate.TeamID):
	Origin = _origin
	Allegience = _allegience
	Source = _source
	CurrentMap = _map

	if Origin != null:
		position = Origin.GlobalPosition

func Enter():
	ExecutionComplete = false

func UpdateGridEntity_TeamTurn(_delta : float):
	return true

func UpdateGridEntity_UnitTurn(_delta : float):
	return true

func ToJSON():
	var dict = {
		"prefab" : self.scene_file_path,
		"Allegience" : Allegience,
		"Expired" : Expired,
		"ExecutionComplete" : ExecutionComplete,
		"type" : "GridEntityBase",
		"OriginPosition" : Origin.Position
	}

	if Source != null:
		dict["SourceAllegience"] = Source.UnitAllegiance
		dict["SourceUnitTemplate"] = Source.Template.resource_path
		dict["SourceUnitPosition"] = Source.GridPosition

	return dict

func InitFromJSON(_dict : Dictionary):
	CurrentMap = Map.Current # If we're loading from JSON, there's no ambiguity here
	Allegience = _dict["Allegience"]
	Expired = _dict["Expired"]
	ExecutionComplete = _dict["ExecutionComplete"]
	Origin = Map.Current.grid.GetTile(PersistDataManager.String_To_Vector2i(_dict["OriginPosition"]))

	if _dict.has("SourceUnitTemplate"):
		var units = Map.Current.GetUnitsOnTeam(_dict["SourceAllegience"])
		for u : UnitInstance in units:
			if u.Template.resource_path == _dict["SourceUnitTemplate"] && u.GridPosition == PersistDataManager.String_To_Vector2i(_dict["SourceUnitPosition"]):
				Source = u
				return

	pass


static func FromJSON(_dict : Dictionary):
	var gridEntityBase

	match _dict["type"]:
		"GridEntityBase":
			gridEntityBase = load(_dict["prefab"]).instantiate() as GridEntityBase
		"GEProjectile":
			gridEntityBase = load(_dict["prefab"]).instantiate() as GEProjectile

	gridEntityBase.InitFromJSON(_dict)
	return gridEntityBase
