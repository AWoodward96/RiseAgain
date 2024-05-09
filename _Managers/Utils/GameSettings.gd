extends Resource
class_name GameSettings


enum TeamID { ALLY = 1, ENEMY = 2, NEUTRAL = 4 }

@export var PlayerControllerPrefab : PackedScene
@export var DerivedStatDefinitions : Array[DerivedStatDef]

@export var MovementStat : StatTemplate
@export var HealthStat : StatTemplate


@export var CharacterTileMovemementSpeed : float = 100

func DamageCalculation(_atk, _def):
	return (_atk * 1.5) - _def
