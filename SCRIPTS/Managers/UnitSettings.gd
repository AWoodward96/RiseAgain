extends Resource
class_name UnitSettingsTemplate

@export var UnitInstancePrefab : PackedScene
@export var AllyUnitManifest : Array[UnitTemplate]

@export var BaseUnitPrestiegeCost : int = 100
@export var AdditionalUnitPrestiegeCost : int = 10
@export var PrestiegeGrantedPerMap : int = 10



func GetPrestiegeBreakpoint(_currentLevel : int):
	return BaseUnitPrestiegeCost + (_currentLevel * AdditionalUnitPrestiegeCost)
