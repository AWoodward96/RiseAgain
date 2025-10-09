extends Object
class_name MovementData


var Route : Array[Tile]
var DestinationTile : Tile
var SpeedOverride : int = -1

var Log : ActionLog
var SourceAbility : Ability

var IsPush : bool = false
var CutsceneMove : bool = false
var AllowOccupantOverwrite : bool = false
var AnimationStyle : UnitSettingsTemplate.EMovementAnimationStyle = UnitSettingsTemplate.EMovementAnimationStyle.Normal

var MoveFromAbility : bool :
	get:
		return SourceAbility != null


func AssignAbilityData(_source : Ability, _log : ActionLog):
	SourceAbility = _source
	Log = _log

static func Construct(_route : Array[Tile], _destinationTile : Tile):
	var newMovementData = MovementData.new()
	newMovementData.Route = _route
	newMovementData.DestinationTile = _destinationTile
	return newMovementData
