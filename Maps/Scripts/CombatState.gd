extends MapStateBase
class_name CombatState

var currentlySelectedUnit : UnitInstance
var currentTurn = GameSettings.TeamID

var combatHud
var unitTurnStack : Array[UnitInstance]
var currentUnitsTurn : UnitInstance

var IsAllyTurn : bool :
	get :
		return currentTurn == GameSettings.TeamID.ALLY

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	combatHud = controller.EnterSelectionState()
	controller.ClearSelectionData()

	StartTurn(GameSettings.TeamID.ALLY)
	ActivateAll()

func Update(_delta):
	if controller.BlockMovementInput:
		return

	match currentTurn:
		GameSettings.TeamID.ALLY:
			# Do nothing, let the player do their thing
			pass
		GameSettings.TeamID.ENEMY:
			UpdateEnemyTurn(_delta)
		GameSettings.TeamID.NEUTRAL:
			UpdateNeutralTurn(_delta)

	if IsTurnOver():
		var nextTurn
		# TODO: Figure out the best way to determine whose turn it is up next
		match currentTurn:
			GameSettings.TeamID.ALLY:
				#if map.teams.has(GameSettings.TeamID.ENEMY) && map.teams[GameSettings.TeamID.ENEMY].size() > 0:
				nextTurn = GameSettings.TeamID.ENEMY
			GameSettings.TeamID.ENEMY:
				nextTurn = GameSettings.TeamID.ALLY
			# TODO: Neutral turns
			GameSettings.TeamID.NEUTRAL:
				nextTurn = GameSettings.TeamID.ALLY
		StartTurn(nextTurn)

func StartTurn(_turn : GameSettings.TeamID):
	currentTurn = _turn
	map.grid.RefreshGridForTurn(currentTurn)

	controller.BlockMovementInput = true
	combatHud.PlayTurnStart(_turn)
	await combatHud.TurnStartAnimComplete
	controller.BlockMovementInput = false

	if _turn == GameSettings.TeamID.ALLY:
		controller.EnterSelectionState()

	if _turn != GameSettings.TeamID.ALLY:
		unitTurnStack = map.GetUnitsOnTeam(_turn)

	currentUnitsTurn = null
	ActivateAll()

func ActivateAll():
	for team in map.teams:
		# 'team' in this scenario is an ENUM, so check against map.teams[team]
		for unit in map.teams[team] :
			if unit != null:
				unit.Activate()

func IsTurnOver():
	var turnOver = true
	if !map.teams.has(currentTurn):
		return turnOver

	var currentUnits = map.teams[currentTurn]
	for unit in currentUnits:
		if unit == null:
			continue
		if unit.Activated:
			turnOver = false

	return turnOver

func OnTileSelected(_tile : Tile):
	super(_tile)

	if _tile.Occupant != null :
		if currentlySelectedUnit == null:
			currentlySelectedUnit = _tile.Occupant

			map.grid.ShowUnitActions(currentlySelectedUnit)
			if currentlySelectedUnit.UnitAllegiance == GameSettings.TeamID.ALLY && IsAllyTurn:
				controller.StartMovementTracker(currentlySelectedUnit.GridPosition)
	else:
		if currentlySelectedUnit != null && currentlySelectedUnit.UnitAllegiance == GameSettings.TeamID.ALLY && _tile.CanMove:
			var path = map.grid.Pathfinding.get_point_path(currentlySelectedUnit.GridPosition, _tile.Position)
			currentlySelectedUnit.MoveCharacterToNode(path, _tile)

		ClearTileSelection()

func ClearTileSelection():
	currentlySelectedUnit = null
	map.grid.ClearActions()
	controller.EndMovementTracker()

func UpdateEnemyTurn(_delta):
	if !map.teams.has(GameSettings.TeamID.ENEMY):
		return

	if currentUnitsTurn == null:
		currentUnitsTurn = unitTurnStack.pop_front()
		if currentUnitsTurn != null:
			currentUnitsTurn.AI.StartTurn(map, currentUnitsTurn)
	else:
		currentUnitsTurn.AI.RunTurn()
		if !currentUnitsTurn.Activated && currentUnitsTurn.IsStackFree:
			currentUnitsTurn = null

func UpdateNeutralTurn(_delta):
	pass
