@tool
extends SpawnerBase
class_name SpawnerGridEntity

@export var GridEntityPrefab : PackedScene
@export var Direction : GameSettingsTemplate.Direction

func SpawnEnemy(_map : Map, _rng : RandomNumberGenerator):
	if GridEntityPrefab == null || !Enabled:
		return

	var gridentity = GridEntityPrefab.instantiate() as GridEntityBase
	if gridentity == null:
		return

	if gridentity.get("direction") != null:
		gridentity.direction = Direction

	var tile = _map.grid.GetTile(Position)
	gridentity.Spawn(_map, tile, null, Allegiance)
	_map.AddGridEntity(gridentity)
