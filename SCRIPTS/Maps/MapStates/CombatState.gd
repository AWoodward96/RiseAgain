extends MapStateBase
class_name CombatState

var currentlySelectedUnit : UnitInstance

var combatHud
var unitTurnStack : Array[UnitInstance]
var currentUnitsTurn : UnitInstance
var turnBannerOpen : bool

var preTurnUpdate : bool :
	get:
		return teamTurnUpdate || unitTurnUpdate || fireUpdate || nextSpawner != null

var teamTurnUpdate : bool
var unitTurnUpdate : bool
var preTurnComplete : bool
var preTurnAvailableSpawners : Array[SpawnerBase]
var nextSpawner : SpawnerBase


var turnStartFocusSubject : Tile
var turnStartFocusDelta : float

var fireUpdate : bool
var fireDamageTiles : Array[Tile]

var IsAllyTurn : bool :
	get :
		return map.currentTurn == GameSettingsTemplate.TeamID.ALLY

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	InitializeFromPersistence(_map, _ctrl)

	StartTurn(GameSettingsTemplate.TeamID.ALLY)
	ActivateAll()

func InitializeFromPersistence(_map : Map, _ctrl : PlayerController):
	map = _map
	controller = _ctrl

	combatHud = controller.CreateCombatHUD()
	controller.ClearSelectionData()

	if !map.OnUnitTurnEnd.is_connected(OnUnitEndTurn):
		map.OnUnitTurnEnd.connect(OnUnitEndTurn)

	UpdateCurrentTurnInfo()


func Exit():
	if map.OnUnitTurnEnd.is_connected(OnUnitEndTurn):
		map.OnUnitTurnEnd.disconnect(OnUnitEndTurn)

func Update(_delta):
	if turnBannerOpen:
		return

	if preTurnUpdate:
		if preTurnAvailableSpawners.size() > 0 || nextSpawner != null:
			UpdateTurnStartSpawn(_delta)
			return

		if teamTurnUpdate || unitTurnUpdate:
			UpdateGridEntities(_delta)
			return

		if fireUpdate:
			UpdateFireDamage(_delta)
			return
		return
	elif !preTurnComplete:
		# the preturn should be complete now, save the map
		if map.AutosaveEnabled:
			PersistDataManager.SaveMap()

		if map.currentTurn == GameSettingsTemplate.TeamID.ALLY:
			map.playercontroller.BlockMovementInput = false
		preTurnComplete = true
		map.RemoveExpiredGridEntities()


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
				# only increment the turn count at the end of the enemy's turn
				map.turnCount += 1
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

	UpdateCurrentTurnInfo()

	currentUnitsTurn = null
	ActivateAll()
	map.RemoveExpiredGridEntities()
	map.OnTurnStart.emit(_turn)
	EnterTeamTurnUpdate()
	if map.AutosaveEnabled:
		PersistDataManager.SaveMap()


func UpdateCurrentTurnInfo():
	unitTurnStack = map.GetUnitsOnTeam(map.currentTurn)
	if map.currentTurn == GameSettingsTemplate.TeamID.ALLY:
		controller.EnterSelectionState()

	if map.currentTurn != GameSettingsTemplate.TeamID.ALLY:
		controller.EnterOffTurnState()

	if unitTurnStack.size() > 0:
		controller.ForceReticlePosition(unitTurnStack[0].CurrentTile.Position)


func EnterTeamTurnUpdate():
	preTurnComplete = false
	teamTurnUpdate = true

	if map.currentTurn == GameSettingsTemplate.TeamID.ALLY:
		map.playercontroller.BlockMovementInput = true

	for entities in map.gridEntities:
		if entities.UpdatePerTeamTurn:
			entities.Enter()

	preTurnAvailableSpawners.clear()
	for s in map.spawners:
		if s is SpawnerTurnBased && s.CanSpawn(map):
			preTurnAvailableSpawners.append(s)


	fireDamageTiles = map.grid.UpdateFireDamageTiles(map.currentTurn)
	if fireDamageTiles.size() > 0:
		fireUpdate = true

func EnterUnitTurnUpdate():
	unitTurnUpdate = true
	for entities in map.gridEntities:
		if entities.UpdatePerUnitTurn:
			entities.Enter()

func UpdateTurnStartSpawn(_delta):
	if nextSpawner == null:
		if preTurnAvailableSpawners.size() == 0:
			return

		nextSpawner = preTurnAvailableSpawners.pop_front()
		controller.ForceCameraPosition(nextSpawner.Position)
		turnStartFocusDelta = 0
		return

	elif controller.CameraMovementComplete:
		# yeah this looks a bit scuffed but what this does is basically add a 1s delay after a unit is spawned
		# before something else occurs
		if turnStartFocusDelta == 0:
			nextSpawner.SpawnEnemy(map, map.mapRNG)
		turnStartFocusDelta += _delta
		if turnStartFocusDelta > 1:
			nextSpawner = null

	pass

func UpdateFireDamage(_delta):
	if turnStartFocusSubject == null && fireDamageTiles.size() == 0:
		fireUpdate = false
		return

	turnStartFocusDelta += _delta
	if turnStartFocusDelta < 0:
		return

	if fireDamageTiles.size() > 0 && turnStartFocusSubject == null:
		var pop = fireDamageTiles.pop_front() as Tile
		if pop != null:
			turnStartFocusSubject = pop
			turnStartFocusDelta = 0
			map.playercontroller.ForceCameraPosition(turnStartFocusSubject.Position)

	if turnStartFocusDelta > 1:
		match turnStartFocusSubject.FireLevel:
			1:
				if map.currentTurn == GameSettingsTemplate.TeamID.ALLY: map.grid.ModifyTileHealth(GameManager.GameSettings.Level1FireDamage, turnStartFocusSubject)
				if turnStartFocusSubject.Occupant != null : turnStartFocusSubject.Occupant.ModifyHealth(GameManager.GameSettings.Level1FireDamage, null, true)
			2:
				if map.currentTurn == GameSettingsTemplate.TeamID.ALLY: map.grid.ModifyTileHealth(GameManager.GameSettings.Level2FireDamage, turnStartFocusSubject)
				if turnStartFocusSubject.Occupant != null : turnStartFocusSubject.Occupant.ModifyHealth(GameManager.GameSettings.Level2FireDamage, null, true)
			3:
				if map.currentTurn == GameSettingsTemplate.TeamID.ALLY: map.grid.ModifyTileHealth(GameManager.GameSettings.Level3FireDamage, turnStartFocusSubject)
				if turnStartFocusSubject.Occupant != null : turnStartFocusSubject.Occupant.ModifyHealth(GameManager.GameSettings.Level3FireDamage, null, true)
		turnStartFocusSubject = null
		turnStartFocusDelta = -0.5


func UpdateGridEntities(_delta):
	if teamTurnUpdate:
		var over = true
		for entities in map.gridEntities:
			if entities.UpdatePerTeamTurn:
				over = entities.UpdateGridEntity_TeamTurn(_delta) && over

		if over:
			teamTurnUpdate = false
			UpdateCurrentTurnInfo()

	if unitTurnUpdate:
		var over = true
		for entities in map.gridEntities:
			if entities.UpdatePerUnitTurn:
				over = entities.UpdateGridEntity_UnitTurn(_delta) &&  over

		if over:
			unitTurnUpdate = false

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

func OnUnitEndTurn(_unitInstance : UnitInstance):
	EnterUnitTurnUpdate()

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
				if currentUnitsTurn.AggroType != null:
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

func ToJSON():
	return "CombatState"
