extends Resource
class_name GameSettings


enum TeamID { ALLY = 1, ENEMY = 2, NEUTRAL = 4 }

@export var PlayerControllerPrefab : PackedScene
@export var DerivedStatDefinitions : Array[DerivedStatDef]

@export var MovementStat : StatTemplate
@export var HealthStat : StatTemplate


@export var CharacterTileMovemementSpeed : float = 100

