extends GridEntityBase
class_name GEProjectile

@export var shapedTiles : TargetingShapeBase
@export var tilesToMovePerTurn : int = 1
@export var damageData : DamageData
@export var visual : Node2D
@export var moveSpeed : float = 100
@export var cameraFocusWarmup : float = 0.25

var delay : float
var tiles : Array[TileTargetedData]
var moved : bool = false

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID, _direction : GameSettingsTemplate.Direction):
	super(_map, _origin, _source, _ability, _allegience, _direction)
	RefreshVisual()
	UpdatePositionOnGrid()

func RefreshVisual():
	if visual != null:
		visual.rotation = deg_to_rad(90 * Direction)

		match(Direction):
			0:
				visual.position = Vector2i(0, 0)
			1:
				visual.position = Vector2i(32, 0)
			2:
				visual.position = Vector2i(32, 32)
			3:
				visual.position = Vector2i(0, 32)


func UpdatePositionOnGrid():
	if shapedTiles == null:
		push_error("Grid Entity Projectile is missing their shaped tiles. " + self.name)
		return

	var newTiles = shapedTiles.GetTargetedTilesFromDirection(Source, null, CurrentMap.grid, Origin, Direction, 0, false, false,  false)
	for t in tiles:
		if t == null || t.Tile == null:
			continue

		t.Tile.RemoveEntity(self)

	tiles = newTiles
	for t in tiles:
		if t == null || t.Tile == null:
			continue

		t.Tile.AddEntity(self)
	pass

func MoveAndDealDamage():
	var newTile = CurrentMap.grid.GetTile(Origin.Position + GameSettingsTemplate.GetVectorFromDirection(Direction))
	if newTile == null:
		Expired = true
		return

	Origin = newTile
	UpdatePositionOnGrid()

	for t in tiles:
		if t == null || t.Tile == null || t.Tile.Occupant == null:
			continue

		t.Tile.Occupant.ModifyHealth(-GameManager.GameSettings.DamageCalculation(Source, t.Tile.Occupant, damageData, t, SourceAbility), null, false)

func Enter():
	super()
	delay = 0
	moved = false

func CommonUpdate(_delta : float):
	delay += _delta

	#if CurrentMap.playercontroller != null:
		#CurrentMap.playercontroller.ForceCameraPosition(Origin.Position)

	if delay >= cameraFocusWarmup:
		if !moved:
			MoveAndDealDamage()
			moved = true

		var destination = Origin.GlobalPosition
		var distance = position.distance_squared_to(destination)
		var maximumDistanceTraveled = moveSpeed * _delta
		if distance < (maximumDistanceTraveled * maximumDistanceTraveled) :
			#AudioFootstep.play()
			position = Origin.GlobalPosition
			ExecutionComplete = moved
		else:
			var velocity = (destination - position).normalized() * moveSpeed
			position += velocity * _delta

func UpdateGridEntity_TeamTurn(_delta : float):
	CommonUpdate(_delta)
	return ExecutionComplete

func UpdateGridEntity_UnitTurn(_delta : float):
	CommonUpdate(_delta)
	return ExecutionComplete

func Exit():
	for t in tiles:
		if t == null || t.Tile == null:
			continue

		t.Tile.RemoveEntity(self)

func ToJSON():
	var dict = super()
	dict["type"] = "GEProjectile"
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	RefreshVisual()
	UpdatePositionOnGrid()
	position = Origin.GlobalPosition
	pass
