extends PassiveListenerBase
class_name PassiveUnitDeathListener

@export var includeSelf : bool
@export var reqKilledByUser : bool
@export var descriptorFilter : DescriptorTemplate
@export var triggerAbilityStack : bool = false



func RegisterListener(_ability : Ability, _map : Map):
	super(_ability, _map)
	_map.OnUnitDied.connect(OnDeath)
	pass

func OnDeath(_unitThatDied : UnitInstance, _context : DamageStepResult):
	var passes = false
	if includeSelf && _unitThatDied == ability.ownerUnit:
		passes = true

	if descriptorFilter != null:
		if _unitThatDied.Template.Descriptors.has(descriptorFilter):
			passes = true
		else:
			passes = false

	if reqKilledByUser && _context.Source != ability.ownerUnit:
		passes = false

	if passes && triggerAbilityStack:
		var passiveInstance = PassiveAbilityAction.Construct(ability.ownerUnit, ability)
		passiveInstance.executionStack = ability.executionStack
		passiveInstance.log.actionOriginTile = _unitThatDied.CurrentTile

		if ability.TargetingData != null:
			passiveInstance.log.affectedTiles = ability.TargetingData.GetAffectedTiles(_unitThatDied, Map.Current.grid, _unitThatDied.CurrentTile)

		passiveInstance.BuildResults()
		Map.Current.AppendPassiveAction(passiveInstance)

	pass
