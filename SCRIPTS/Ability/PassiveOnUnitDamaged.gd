extends PassiveListenerBase
class_name PassiveOnUnitDamaged

@export var executionStack : Array[ActionStep]
@export var useDamageTypeReq : bool = false
@export var damageTypeReq : DamageData.EDamageClassification


func RegisterListener(_ability : Ability, _map : Map):
	super(_ability, _map)
	# TBD: If I want something to trigger when any unit is damaged, I'm gonna need to find a new solution
	# BUT
	# For now this is fine
	_ability.ownerUnit.OnUnitDamaged.connect(OnUnitDamaged)
	pass

func OnUnitDamaged(_result : DamageStepResult):
	if useDamageTypeReq:
		if _result.AbilityData == null || _result.AbilityData.UsableDamageData == null:
			return

		if _result.AbilityData.UsableDamageData.DamageType != damageTypeReq:
			return

	var passiveInstance = PassiveAbilityAction.Construct(ability.ownerUnit, ability)
	passiveInstance.executionStack = executionStack
	passiveInstance.log.ability = ability
	passiveInstance.log.actionOriginTile = ability.ownerUnit.CurrentTile

	if ability.TargetingData != null:
		passiveInstance.log.affectedTiles = ability.TargetingData.GetAffectedTiles(ability.ownerUnit, Map.Current.grid, ability.ownerUnit.CurrentTile)


	passiveInstance.BuildResults()
	Map.Current.AppendPassiveAction(passiveInstance)
