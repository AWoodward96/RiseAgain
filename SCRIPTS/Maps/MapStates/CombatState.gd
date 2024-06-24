extends MapStateBase
class_name CombatState

var currentlySelectedUnit : UnitInstance

var combatHud
var unitTurnStack : Array[UnitInstance]
var currentUnitsTurn : UnitInstance
var turnBannerOpen : bool


var IsAllyTurn : bool :
	get :
		return map.currentTurn == GameSettings.TeamID.ALLY

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	combatHud = controller.CreateCombatHUD()
	controller.ClearSelectionData()

	StartTurn(GameSettings.TeamID.ALLY)
	ActivateAll()

func Update(_delta):
	if turnBannerOpen:
		return

	match map.currentTurn:
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
		match map.currentTurn:
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
	map.currentTurn = _turn
	map.grid.RefreshGridForTurn(map.currentTurn)

	controller.BlockMovementInput = true
	combatHud.PlayTurnStart(_turn)
	turnBannerOpen = true
	await combatHud.BannerAnimComplete
	controller.BlockMovementInput = false
	turnBannerOpen = false

	unitTurnStack = map.GetUnitsOnTeam(_turn)
	if _turn == GameSettings.TeamID.ALLY:
		controller.EnterSelectionState()

	if _turn != GameSettings.TeamID.ALLY:
		controller.EnterOffTurnState()

	controller.ForceReticlePosition(unitTurnStack[0].CurrentTile.Position)
	currentUnitsTurn = null
	ActivateAll()

func ActivateAll():
	for team in map.teams:
		# 'team' in this scenario is an ENUM, so check against map.teams[team]
		for unit in map.teams[team] :
			if unit != null:
				unit.Activate(map.currentTurn)

func IsTurnOver():
	var turnOver = true
	if !map.teams.has(map.currentTurn):
		return turnOver

	var allUnits = map.teams[map.currentTurn]
	for team in map.teams:
		var isCurrent = map.currentTurn == team
		for unit in map.teams[team]:
			if unit == null:
				continue

			# don't end the turn if there is a unit on the current turns team that is activated
			if isCurrent && unit.Activated:
				turnOver = false

			# also don't end the turn if there is a unit with something on its stack
			if !unit.IsStackFree:
				turnOver = false

	return turnOver


func ClearTileSelection():
	currentlySelectedUnit = null
	map.grid.ClearActions()
	controller.EndMovementTracker()

func UpdateEnemyTurn(_delta):
	if !map.teams.has(GameSettings.TeamID.ENEMY):
		return

	if currentUnitsTurn == null:
		var pop = unitTurnStack.pop_front()
		if pop == null:
			return

		currentUnitsTurn = pop as UnitInstance
		if currentUnitsTurn != null:
			if !currentUnitsTurn.IsAggrod:
				currentUnitsTurn.IsAggrod = currentUnitsTurn.AggroType.Check(currentUnitsTurn, map)

			if currentUnitsTurn.IsAggrod:
				if currentUnitsTurn.AI == null:
					push_error("Unit: ", currentUnitsTurn, " - Has No AI. Defaulting to EndTurn, but this needs to be fixed")
					currentUnitsTurn.QueueEndTurn()
					currentUnitsTurn = null
				else:
					currentUnitsTurn.AI.StartTurn(map, currentUnitsTurn)
			else:
				currentUnitsTurn.QueueEndTurn()
				currentUnitsTurn = null
	else:
		currentUnitsTurn.AI.RunTurn()
		if !currentUnitsTurn.Activated && currentUnitsTurn.IsStackFree:
			currentUnitsTurn = null

func UpdateNeutralTurn(_delta):
	pass
