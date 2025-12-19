extends ArmorEffectInstance
class_name SnapBlossomEffectInstance

var detonated : bool = false



func OnEffectRemoved():
	Detonate()
	pass

func Detonate():
	if !detonated:
		detonated = true

		var castTemplate = Template as SnapBlossomEffectTemplate
		var newPassiveAction = PassiveAbilityAction.Construct(AbilitySource.ownerUnit, AbilitySource) as PassiveAbilityAction

		var tiles = castTemplate.explosionShape.GetTileData(SourceUnit, AbilitySource, Map.Current.grid, AffectedUnit.CurrentTile, 0)
		tiles = SkillTargetingData.FilterByTargettingFlags(SkillTargetingData.TargetingType.ShapedFree, castTemplate.teamTargeting, false, SourceUnit, tiles)

		newPassiveAction.AssignAffectedTiles(AffectedUnit.CurrentTile, tiles)
		newPassiveAction.AddCameraFocusStep()
		newPassiveAction.AddDelayStep()
		newPassiveAction.AddPlayAbilityPopup()

		var vfx = CreateVFXStep.new()
		vfx.PositionOnActionOrigin = true
		vfx.PositionOnSource = false
		vfx.VFXPrefab = castTemplate.vfx
		newPassiveAction.executionStack.append(vfx)

		var combatStep = PerformCombatStep.new()
		newPassiveAction.executionStack.append(combatStep)
		newPassiveAction.AddGainEXPStep()


		newPassiveAction.BuildResults()
		Map.Current.AppendPassiveAction(newPassiveAction)

	pass


func ToJSON():
	var dict = super()
	dict["type"] = "SnapBlossomEffectInstance"
	dict["detonated"] = detonated
	return dict


func InitFromJSON(_dict, _map : Map):
	super(_dict, _map)
	detonated = _dict["detonated"]
