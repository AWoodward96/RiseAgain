extends Node2D
class_name GridEntityBase

@export var UpdatePerTeamTurn : bool
@export var UpdatePerUnitTurn : bool
@export var PreviewSprite : Texture2D

@export_category("Localization")
@export var localization_icon : Texture2D
@export var localization_desc : String

var Origin : Tile
var Allegience : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ENEMY
var Source : UnitInstance
var SourceAbility : Ability
var CurrentMap : Map
var Expired : bool = false
var ExecutionComplete : bool = false

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID):
	Origin = _origin
	Allegience = _allegience
	Source = _source
	SourceAbility = _ability
	CurrentMap = _map

	if Origin != null:
		position = Origin.GlobalPosition

func Enter():
	ExecutionComplete = false

func UpdateGridEntity_TeamTurn(_delta : float):
	return true

func UpdateGridEntity_UnitTurn(_delta : float):
	return true

# Returns true if a units' movement should be interrupted
func OnUnitTraversed(_unitInstance : UnitInstance, _tile : Tile):
	return false

func Exit():
	pass

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

		if SourceAbility != null:
			# This is technically not possible if source is null
			dict["SourceAbility"] = SourceAbility.internalName

	return dict

func GetLocalizedDescription(_tile : Tile):
	return tr(localization_desc)

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
				for ability in u.Abilities:
					if ability != null && ability.internalName == _dict["SourceAbility"]:
						SourceAbility = ability
				return

	pass


static func FromJSON(_dict : Dictionary):
	var gridEntityBase

	match _dict["type"]:
		"GridEntityBase":
			gridEntityBase = load(_dict["prefab"]).instantiate() as GridEntityBase
		"GEProjectile":
			gridEntityBase = load(_dict["prefab"]).instantiate() as GEProjectile
		"GEProximityBomb":
			gridEntityBase = load(_dict["prefab"]).instantiate() as GEProximityBomb
		"GEStaticAreaOfEffect":
			gridEntityBase = load(_dict["prefab"]).instantiate() as GEStaticAreaOfEffect

	gridEntityBase.InitFromJSON(_dict)
	return gridEntityBase
