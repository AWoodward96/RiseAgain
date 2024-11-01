extends MapStateBase
class_name CampsiteState


func Enter(_map : Map, _ctrl : PlayerController):
	super(_map,_ctrl)

	if map.teams.size() == 0:
		push_error("Teams are empty when Premap selection is hit. This is an error")
		return

	#set the controllers position
	controller.ForceReticlePosition(map.startingPositions[0])
	controller.ForceCameraPosition(map.CameraStart)
	controller.ClearSelectionData()
	controller.EnterCampsiteState()

	var campsite = CampsiteUI.ShowUI()

	for startingP in map.StartingPositionsParent.get_children():
		startingP.hide()

	await campsite.OnRest


	var screen = GameManager.ShowLoadingScreen()
	await screen.ScreenObscured

	var restedUI = UIManager.CampsiteRestedPopupPrefab.instantiate()
	UIManager.add_child(restedUI)

	await restedUI.OnClose

	var units = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	for u in units:
		u.Rest()



	if map.CurrentCampaign != null:
		map.CurrentCampaign.MapComplete()
	pass
