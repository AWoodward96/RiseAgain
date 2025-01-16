extends MapStateBase
class_name PreMapState


func Enter(_map : Map, _ctrl : PlayerController):
	super(_map,_ctrl)

	if map.teams.size() == 0:
		push_error("Teams are empty when Premap selection is hit. This is an error")
		return

	#set the controllers position
	controller.ForceReticlePosition(map.startingPositions[0])
	controller.ForceCameraPosition(map.CameraStart)
	controller.ClearSelectionData()

	# spawn all Units
	for spawner in map.spawners:
		spawner.SpawnEnemy(map, map.mapRNG)
		spawner.hide()

	var formationUI = controller.EnterFormationState()
	await formationUI.FormationSelected

	for startingP in map.StartingPositionsParent.get_children():
		startingP.hide()

	map.ChangeMapState(CombatState.new())
	pass

func ToJSON():
	return "PreMapState"
