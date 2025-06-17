extends MapStateBase
class_name PreMapState

var formationUI

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map,_ctrl)

	if map.teams.size() == 0:
		push_error("Teams are empty when Premap selection is hit. This is an error")
		return

	#set the controllers position
	controller.ForceReticlePosition(map.startingPositions[0])
	controller.ForceCameraPosition(map.CameraStart, true)
	controller.ClearSelectionData()

	# spawn all Units
	for spawner in map.spawners:
		if spawner is not SpawnerTurnBased:
			spawner.SpawnEnemy(map, map.mapRNG)
		elif spawner.CanSpawn(map):
			spawner.SpawnEnemy(map, map.mapRNG)

		spawner.hide()

	MakeEveryoneLookActive()

	if map.PreMapCutscene != null:
		for startingP in map.StartingPositionsParent.get_children():
			startingP.hide()
		CutsceneManager.QueueCutscene(map.PreMapCutscene)
	else:
		PromptFormation()
	pass

func InitializeFromPersistence(_map : Map, _ctrl : PlayerController):
	map = _map
	controller = _ctrl
	controller.ForceReticlePosition(map.startingPositions[0])
	controller.ForceCameraPosition(map.CameraStart, true)
	controller.ClearSelectionData()
	MakeEveryoneLookActive()

	formationUI = controller.EnterFormationState()
	await formationUI.FormationSelected
	map.ChangeMapState(CombatState.new())

func MakeEveryoneLookActive():
	for teamID in map.teams:
		for unit : UnitInstance in map.teams[teamID]:
			unit.Activated = true

func PromptFormation():
	formationUI = controller.EnterFormationState()
	await formationUI.FormationSelected
	map.ChangeMapState(CombatState.new())

func Exit():
	if formationUI != null:
		formationUI.queue_free()

	for startingP in map.StartingPositionsParent.get_children():
		startingP.hide()

func ToJSON():
	return "PreMapState"
