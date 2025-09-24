extends GridEntityBase
class_name GEStaticAreaOfEffect

enum DamageInterval { DamageOnTurnStart, DamageOnTraversal }


@export var shaped_tiles : TargetingShapeBase
@export var team_targeting : SkillTargetingData.TargetingTeamFlag = SkillTargetingData.TargetingTeamFlag.EnemyTeam
@export var damage_interval : DamageInterval
@export var turn_specific_update : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY
@export var interruptionType : GameSettingsTemplate.TraversalResult
@export var damage_data : DamageData
@export var heal_data : HealComponent
@export var duration : int = 3

@export_category("Camera Focus Speed")
@export var warmup_timer : float = 0.5
@export var cooloff_timer : float = 1


var remaining_duration : int
var tiles : Array[TileTargetedData]
var warmup : float = 0
var cooloff : float = 0
var affected : bool = false

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID, _direction : GameSettingsTemplate.Direction):
	super(_map, _origin, _source, _ability, _allegience, _direction)
	UpdatePositionOnGrid()
	remaining_duration = duration


func Enter():
	super()
	warmup = 0
	cooloff = 0
	affected = false
	if CurrentMap.currentTurn == turn_specific_update:
		CurrentMap.playercontroller.ForceCameraPosition(Origin.Position)
		remaining_duration -= 1
	Expired = remaining_duration <= 0

func UpdateGridEntity_TeamTurn(_delta : float):
	if damage_interval == DamageInterval.DamageOnTurnStart && CurrentMap.currentTurn == turn_specific_update:
		if !ExecutionComplete:
			warmup += _delta
			cooloff += _delta

			if warmup > warmup_timer && !affected:
				affected = true
				for t in tiles:
					if t != null && t.Tile.Occupant != null && OnCorrectTeam(Source, t.Tile.Occupant):
						AffectUnit(t.Tile.Occupant, t)

			if cooloff > warmup_timer + cooloff_timer:
				ExecutionComplete = true
	else:
		ExecutionComplete = true

	return ExecutionComplete

func OnCorrectTeam(_thisUnit : UnitInstance, _otherUnit : UnitInstance):
	if team_targeting == SkillTargetingData.TargetingTeamFlag.Empty:
		return _otherUnit == null

	return (_otherUnit.UnitAllegiance == _thisUnit.UnitAllegiance && team_targeting == SkillTargetingData.TargetingTeamFlag.AllyTeam) || (_otherUnit.UnitAllegiance != _thisUnit.UnitAllegiance && team_targeting == SkillTargetingData.TargetingTeamFlag.EnemyTeam) || team_targeting == SkillTargetingData.TargetingTeamFlag.All

func UpdatePositionOnGrid():
	if shaped_tiles == null:
		push_error("Grid Entity Projectile is missing their shaped tiles. " + self.name)
		return

	var newTiles = shaped_tiles.GetTargetedTilesFromDirection(Source, SourceAbility, CurrentMap.grid, Origin, GameSettingsTemplate.Direction.Up, 0, false, false, false)
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

func AffectUnit(_unitInstance : UnitInstance, _relatedTile : TileTargetedData):
	if damage_data != null:
		var newDamageStepResult = DamageStepResult.new()
		newDamageStepResult.Source = Source
		newDamageStepResult.AbilityData = SourceAbility

		newDamageStepResult.HealthDelta = -GameManager.GameSettings.DamageCalculation(Source, _unitInstance, damage_data, _relatedTile)

		_unitInstance.ModifyHealth(newDamageStepResult.HealthDelta, newDamageStepResult, true)

	if heal_data != null:
		var newHealStepResult = HealStepResult.new()
		newHealStepResult.Source = Source
		newHealStepResult.AbilityData = SourceAbility

		newHealStepResult.HealthDelta = GameManager.GameSettings.HealCalculation(heal_data, Source, _relatedTile.AOEMultiplier)

		_unitInstance.ModifyHealth(newHealStepResult.HealthDelta, newHealStepResult, true)


func GetLocalizedDescription(_tile : Tile):
	var tileData = GetTileTargetDataFromTile(_tile)
	if tileData == null:
		return ""

	var returnString = tr(localization_desc)
	var madlibs = {}
	if damage_data != null:
		madlibs["NUM"] = -GameManager.GameSettings.DamageCalculation(Source, null, damage_data, tileData)

	if heal_data != null:
		madlibs["NUM"] = GameManager.GameSettings.HealCalculation(heal_data, Source, tileData.AOEMultiplier)


	return returnString.format(madlibs)

func GetTileTargetDataFromTile(_tile : Tile):
	for t in tiles:
		if t.Tile == _tile:
			return t

	return null

func OnUnitTraversed(_unitInstance : UnitInstance, _tile : Tile):
	if damage_interval != DamageInterval.DamageOnTraversal:
		return GameSettingsTemplate.TraversalResult.OK

	var pairedTile : TileTargetedData = null
	for t in tiles:
		if t.Tile == _tile:
			pairedTile = t

	if pairedTile == null:
		return GameSettingsTemplate.TraversalResult.OK

	if OnCorrectTeam(Source, _unitInstance):
		AffectUnit(_unitInstance, pairedTile)

	return interruptionType

func Exit():
	for t in tiles:
		if t == null || t.Tile == null:
			continue

		t.Tile.RemoveEntity(self)

func ToJSON():
	var dict = super()
	dict["type"] = "GEStaticAreaOfEffect"
	dict["remaining_duration"] = remaining_duration
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	position = Origin.GlobalPosition
	remaining_duration = int(_dict["remaining_duration"])
	UpdatePositionOnGrid()
	pass
