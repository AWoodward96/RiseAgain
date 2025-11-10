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


@export var Enabled : bool = true :
	set(value):
		Enabled = value
		OnEnableToggled()

@export var Boss : bool = false
@export_file("*.tscn") var GivenItems : Array[String]
@export var ExtraHealthBars : int = 0
@export var Allegiance : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ENEMY
@export var AIBehavior : AIBehaviorBase
@export var AggroBehavior : AlwaysAggro

func SpawnEnemy(_map: Map, _rng : DeterministicRNG):
	if !Enabled:
		return

func OnEnableToggled():
	pass
