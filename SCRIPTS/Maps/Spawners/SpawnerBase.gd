@tool
extends Node2D
class_name SpawnerBase

const PREFIX = "Spawn_"
const NodeSize : int = 64

@export var DebugName : String
@export var Position: Vector2i :
	set(value):
		Position = value
		position = Position * NodeSize


@export var Enabled : bool = true
@export var Allegiance : GameSettings.TeamID = GameSettings.TeamID.ENEMY
@export var AIBehavior : AIBehaviorBase
@export var AggroBehavior : AlwaysAggro

func SpawnEnemy(_map: Map, _rng : RandomNumberGenerator):
	if !Enabled:
		return
