extends PassiveListenerBase
class_name TurnStartListener

# Should be overwritten to implement actual functionality
# There's no way to really know wtf should happen based on just the unit alone
# So just take one-listener-per-ability approach. How hard could that be?

func RegisterListener(_ability : Ability, _map : Map):
	super(_ability, _map)
	if !_map.OnTurnStart.is_connected(TurnStart):
		_map.OnTurnStart.connect(TurnStart)


func TurnStart(_turn : GameSettingsTemplate.TeamID):
	pass
