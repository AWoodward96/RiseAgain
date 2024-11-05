extends CombatEffectInstance
class_name WildNecroPassiveInstance

func _ready():
	await get_tree().process_frame

	if !Map.Current.OnUnitDied.is_connected(OnUnitDeath):
		Map.Current.OnUnitDied.connect(OnUnitDeath)

func OnUnitDeath(_unitInstance : UnitInstance, _actionResult : ActionResult):
	var map = Map.Current
	if map == null:
		return

	# If it wasn't us that dealt the damage - go away
	if _actionResult.Source != SourceUnit:
		return

	var asNecroPassive = Template as WildNecroPassive
	for u in asNecroPassive.UnitPairs:
		if u.Unit1 == _unitInstance.Template:
			var zombifiedUnit = map.CreateUnit(u.Unit2, _unitInstance.Level)
			map.InitializeUnit(zombifiedUnit, _unitInstance.GridPosition, GameSettingsTemplate.TeamID.ENEMY)
			zombifiedUnit.SetAI(asNecroPassive.SpawnedUnitAI, asNecroPassive.SpawnedUnitAggroBehavior)
			# End the zombified Unit's turn so that it doesn't mess up the turn order
			zombifiedUnit.EndTurn()
			Juice.CreateEffectPopup(zombifiedUnit.CurrentTile, self)
			return # Don't spawn more than one unit here
	pass

# This passive never expires
func IsExpired():
	return false
