extends CutsceneEventBase
class_name InjureUnitEvent

@export var usePosition : bool = false
@export var unitAtPosition : Vector2i
@export var specificUnitInParty : UnitTemplate
@export var randomUnitInParty : bool = false

func Enter(_context : CutsceneContext):
	if unitAtPosition:
		var tile = Map.Current.grid.GetTile(unitAtPosition)
		if tile.Occupant != null:
			tile.Occupant.Injured = true
			tile.Occupant.UpdateDerivedStats()
			_context.ContextDict["UnitInjuredName"] = tr(tile.Occupant.Template.loc_DisplayName)
	elif specificUnitInParty != null:
		if GameManager.CurrentCampaign != null:
			for units in GameManager.CurrentCampaign.CurrentRoster:
				if units.Template == specificUnitInParty:
					units.Injured = true
					units.UpdateDerivedStats()
					_context.ContextDict["UnitInjuredName"] = tr(units.Template.loc_DisplayName)

	elif randomUnitInParty:
		var ableToBeInjured : Array[UnitInstance] = []
		var rng : DeterministicRNG
		if GameManager.CurrentCampaign != null:
			for u in GameManager.CurrentCampaign.CurrentRoster:
				if !u.Injured:
					ableToBeInjured.append(u)
			rng = GameManager.CurrentCampaign.CampaignRng
		else:
			if Map.Current != null:
				for alliedUnit in Map.Current.teams[GameSettingsTemplate.TeamID.ALLY]:
					if !alliedUnit.Injured:
						ableToBeInjured.append(alliedUnit)

				rng = Map.Current.mapRNG


		if ableToBeInjured.size() == 0:
			return true

		var rngNext = rng.NextInt(0, ableToBeInjured.size() - 1)
		ableToBeInjured[rngNext].Injured = true
		ableToBeInjured[rngNext].UpdateDerivedStats()
		_context.ContextDict["UnitInjuredName"] = tr(ableToBeInjured[rngNext].Template.loc_DisplayName)
		pass
	return true
