extends MapStateBase
class_name CombatState

var currentlySelectedUnit : UnitInstance

var combatHud
var unitTurnStack : Array[UnitInstance]
var currentUnitsTurn : UnitInstance
var turnBannerOpen : bool


var IsAllyTurn : bool :
	get :
		return map.currentTurn == GameSettingsTemplate.TeamID.ALLY

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	combatHud = controller.CreateCombatHUD()
	controller.ClearSelectionData()

	StartTurn(GameSettingsTemplate.TeamID.ALLY)
	ActivateAll()

func Update(_delta):
	if turnBannerOpen:
		return

	match map.currentTurn:
		GameSettingsTemplate.TeamID.ALLY:
			# Do nothing, let the player do their thing
			pass
		GameSettingsTemplate.TeamID.ENEMY:
			UpdateEnemyTurn(_delta)
		GameSettingsTemplate.TeamID.NEUTRAL:
			UpdateNeutralTurn(_delta)

	if IsTurnOver():
		var nextTurn

		match map.currentTurn:
			GameSettingsTemplate.TeamID.ALLY:
				if map.teams.has(GameSettingsTemplate.TeamID.NEUTRAL) && map.teams[GameSettingsTemplate.TeamID.NEUTRAL].size() > 0:
					nextTurn = GameSettingsTemplate.TeamID.NEUTRAL
				else:
					nextTurn = GameSettingsTemplate.TeamID.ENEMY
			GameSettingsTemplate.TeamID.ENEMY:
				nextTurn = GameSettingsTemplate.TeamID.ALLY
			GameSettingsTemplate.TeamID.NEUTRAL:
				nextTurn = GameSettingsTemplate.TeamID.ENEMY
		StartTurn(nextTurn)

func StartTurn(_turn : GameSettingsTemplate.TeamID):
	map.currentTurn = _turn
	map.grid.RefreshGridForTurn(map.currentTurn)

	controller.BlockMovementInput = true
	combatHud.PlayTurnStart(_turn)
	turnBannerOpen = true
	await combatHud.BannerAnimComplete
	controller.BlockMovementInput = false
	turnBannerOpen = false

	unitTurnStack = map.GetUnitsOnTeam(_turn)
	if _turn == GameSettingsTemplate.TeamID.ALLY:
		controller.EnterSelectionState()

	if _turn != GameSettingsTemplate.TeamID.ALLY:
		controller.EnterOffTurnState()

	if unitTurnStack.size() > 0:
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

	return turnOver && !(map.playercontroller.ControllerState is ActionExecutionState) # If we're still in action execution then we need to wait for it to resolve


func ClearTileSelection():
	currentlySelectedUnit = null
	map.grid.ClearActions()
	controller.EndMovementTracker()

func UpdateOffTurn(_delta):
	if currentUnitsTurn == null:
		# Wait for the stack to be clear before starting the next turn
		if !map.GlobalStackClear():
			return

		var pop = unitTurnStack.pop_front()
		if pop == null:
			return

		currentUnitsTurn = pop as UnitInstance
		if currentUnitsTurn != null:
			# If for some reason this unit is not activated then just go to the next unit
			if !currentUnitsTurn.Activated:
				currentUnitsTurn = null
				return

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
		if !currentUnitsTurn.Activated:
			currentUnitsTurn = null
			return

		currentUnitsTurn.AI.RunTurn()
		if !currentUnitsTurn.Activated && currentUnitsTurn.IsStackFree:
			currentUnitsTurn = null

func UpdateEnemyTurn(_delta):
	if !map.teams.has(GameSettingsTemplate.TeamID.ENEMY):
		return

	UpdateOffTurn(_delta)


func UpdateNeutralTurn(_delta):
	if !map.teams.has(GameSettingsTemplate.TeamID.NEUTRAL):
		return

	UpdateOffTurn(_delta)
