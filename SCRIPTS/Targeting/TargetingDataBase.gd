extends Resource
class_name TargetingDataBase

@export_category("Common")
enum ETargetingTeamFlag {
	## Units that are on this units team
	AllyTeam,
	## Units that are not on this units team
	EnemyTeam,
	## Units that are on either team
	All,
	## Only target spaces where there are no units
	Empty }

@export var BaseAccuracy : float = 100
@export var TrueHit : bool = false
@export var TargetRange : Vector2i = Vector2i(1, 1)
@export var TeamTargeting : ETargetingTeamFlag = ETargetingTeamFlag.EnemyTeam
@export var CanTargetSelf : bool = false
@export var CanTargetTerrain : bool = true

var ability : Ability
var source : UnitInstance
var log : ActionLog
var ctrl : PlayerController
var currentGrid : Grid
var currentMap : Map
var direction : GameSettingsTemplate.Direction = GameSettingsTemplate.Direction.Up # Used mostly for shaped free rotations

## Called when targeting begins
func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	ability = _log.ability
	source = _log.source
	currentGrid = _log.grid
	currentMap = Map.Current
	log = _log
	ctrl = _ctrl
	ShowAffinityRelations(source.Template.Affinity)
	pass

## Handles the input of this targeting
func HandleInput(_delta):
	pass

## Helper method to get tiles within range of a unit. NOT which tiles are going to be hit by this ability.
func GetTilesInRange(_unit : UnitInstance, _grid : Grid):
	var options : Array[Tile]
	options = _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)
	return options

## The method that determines which tiles actually get hit by this ability
func GetAffectedTiles(_unitInstance : UnitInstance, _targetedTile : Tile, _atRange : int = 0, _atRotation : GameSettingsTemplate.Direction = GameSettingsTemplate.Direction.Up):
	var tile = _targetedTile.AsTargetData()
	if ability.UsableDamageData != null:
		tile.Ignite = ability.UsableDamageData.Ignite
	return [tile]


func GetStandardTargetingFromAvailableTiles():
	var filteredList : Array[Tile] = []
	var unitsFound = []
	for t in log.availableTiles:
		var added = false
		if t.Occupant == null && t.MaxHealth > 0 && t.Health > 0 && CanTargetTerrain:
			filteredList.append(t)
			added = true

		var target = t.Occupant
		if target != null && \
			OnCorrectTeam(TeamTargeting, source, t.Occupant) && \
			# Because some units are bigger than 1x1 and we don't want to count them twice
			!unitsFound.has(target) && \
			!target.ShroudedFromPlayer:
				unitsFound.append(target)
				if !added:
					filteredList.append(t)

	filteredList.sort_custom(SortStandardTargetingOptions)
	return filteredList


func SortStandardTargetingOptions(a : Tile, b : Tile):
	if a == null && b != null:
		return true
	if b == null && a != null:
		return false

	if a.Occupant == null && b.Occupant == null:
		return true

	if a.Occupant != null && b.Occupant == null:
		return true

	if b.Occupant != null && a.Occupant == null:
		return false

	return a.Occupant.currentHealth < b.Occupant.currentHealth

## Filters out targets based on settings
func FilterAffectedTiles(_options : Array[TileTargetedData]):
	return _options.filter(
		func(o : TileTargetedData) :
			if o.HitsEnvironment && o.Tile.MaxHealth > 0 && o.Tile.Health > 0:
				if o.Tile.Occupant == source:
					return CanTargetSelf

				return true

			var target = o.Tile.Occupant
			if ability.IsHeal() && !ability.HealData.IgnoreCanHealCheck:
				if target != null && !target.CanHeal:
					return false

			if target != null  && !target.IsDying:
				if o.willPush:
					return true

				if !OnCorrectTeam(TeamTargeting, source, target):
					return false

				if target != source || (target == source && CanTargetSelf):
					return true

			# This is here because shaped attacks need to show their shape, even if they hit nothing at all
			if ability.TargetingTemplate is TargetingShapedBase:
				return true

			return false)

## Called when the Controller presses confirm on a tile. Should return a true or a false value depending on if we can execute or not
# This is in here because some targeting systems need to know when select is down
func OnTileSelected():
	return Validate()

## Called when the Controller presses cancel. Sometimes I don't want it to cancel out the entire targeting
# Returns true or false if we want to go all the way back to the context state
func OnCancel():
	return true

## Is the current state of the action log acceptable. IE can this ability properly go off?
func Validate():
	return SharedValidation() && InherritedValidation()

## A helper method to detect global blocking of targeting validation. IE: States of the game where you should NEVER be valid
func SharedValidation():
	for res in log.actionStepResults:
		if !res.Validate():
			return false

	if ctrl.forcedTileSelection != null && CutsceneManager.active_cutscene != null && log.actionOriginTile != ctrl.forcedTileSelection:
		return false

	if CutsceneManager.BlockSelectInput:
		return false

	if log.availableTiles.size() == 0:
		return false

	if log.actionOriginTile != null:
		if TeamTargeting == ETargetingTeamFlag.Empty && log.actionOriginTile.Occupant != null:
			return false

	return true

## Should be overwritten with specific validation per-targeting type
func InherritedValidation():
	return true

func ShowPreview():
	ShowAvailableTilesOnGrid()

	# Filter out the tiles that have incorrect targeting on them
	# The hard removal of specific tiles may not be what we want here - but we'll seeeeeeeeeeeeee
	log.affectedTiles = FilterAffectedTiles(log.affectedTiles)
	log.BuildStepResults()

	# Preview the results
	for result in log.actionStepResults:
		result.PreviewResult(currentMap)

	var allPreviews = currentMap.get_tree().get_nodes_in_group("DamageIndicators")
	for preview in allPreviews:
		var previewAsDamageIndicator = preview as DamageIndicator
		if previewAsDamageIndicator != null:
			# Hide any unit that is currently shrouded from the player
			if previewAsDamageIndicator.assignedUnit != null && previewAsDamageIndicator.assignedUnit.ShroudedFromPlayer:
				continue

			previewAsDamageIndicator.ShowPreview()

	pass

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	var isAttack = ability.IsDamage()

	for tileData in log.availableTiles:
		if isAttack:
			tileData.CanAttack = true
		else:
			tileData.CanBuff = true

	currentGrid.ShowActions()

func ClearPreview():
	if log.actionOriginTile != null && log.actionOriginTile.Occupant != null:
		log.actionOriginTile.Occupant.HideDamagePreview()

	ctrl.ClearShapedDirectionalHelper()

	for res in log.actionStepResults:
		res.CancelPreview()

	var allPreviews = currentMap.get_tree().get_nodes_in_group("DamageIndicators")
	for preview in allPreviews:
		var previewAsDamageIndicator = preview as DamageIndicator
		if previewAsDamageIndicator != null:
			previewAsDamageIndicator.PreviewCanceled()


func OnCorrectTeam(_teamTargeting : ETargetingTeamFlag, _thisUnit : UnitInstance, _otherUnit : UnitInstance):
		#if _type == TargetingType.SelfOnly:
		#return _thisUnit == _otherUnit

	if _teamTargeting == ETargetingTeamFlag.Empty:
		return _otherUnit == null

	if _otherUnit == null:
		return false

	return (_otherUnit.UnitAllegiance == _thisUnit.UnitAllegiance && _teamTargeting == ETargetingTeamFlag.AllyTeam) || (_otherUnit.UnitAllegiance != _thisUnit.UnitAllegiance && _teamTargeting == ETargetingTeamFlag.EnemyTeam) || _teamTargeting == ETargetingTeamFlag.All

func ShowAffinityRelations(_affinityTemplate : AffinityTemplate):
	if _affinityTemplate == null:
		source.ShowAffinityRelation(null)

	var unitsOnTeamTargeting : Array[UnitInstance] = []
	match TeamTargeting:
		ETargetingTeamFlag.AllyTeam:
			unitsOnTeamTargeting.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY))
			unitsOnTeamTargeting.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.NEUTRAL))
		ETargetingTeamFlag.EnemyTeam:
			unitsOnTeamTargeting.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY))
		ETargetingTeamFlag.All:
			unitsOnTeamTargeting.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY))
			unitsOnTeamTargeting.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.NEUTRAL))
			unitsOnTeamTargeting.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY))

	for units in unitsOnTeamTargeting:
		units.ShowAffinityRelation(_affinityTemplate)

## Called when targeting ends
func EndTargeting():
	ClearPreview()
	ShowAffinityRelations(null)
	if ctrl != null:
		ctrl.combatHUD.UpdateTargetingInstructions(false, "", {})
	pass

func GetTargetingString():
	return ""
