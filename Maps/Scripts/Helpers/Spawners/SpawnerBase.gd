@tool
extends MapHelper
class_name SpawnerBase

const PREFIX = "Spawn_"

@export var DebugName : String
@export var Enabled : bool = true
@export var Allegiance : GameSettings.TeamID = GameSettings.TeamID.ENEMY
@export var AIBehavior : AIBehaviorBase

func SpawnEnemy(_map: Map, _rng : RandomNumberGenerator):
	if !Enabled:
		return
