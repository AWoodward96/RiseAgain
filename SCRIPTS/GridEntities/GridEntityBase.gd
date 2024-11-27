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
