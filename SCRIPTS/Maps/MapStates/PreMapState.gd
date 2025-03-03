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

	formationUI = controller.EnterFormationState()
	await formationUI.FormationSelected
	map.ChangeMapState(CombatState.new())
	pass


func Exit():
	if formationUI != null:
		formationUI.queue_free()

	for startingP in map.StartingPositionsParent.get_children():
		startingP.hide()

func ToJSON():
	return "PreMapState"
