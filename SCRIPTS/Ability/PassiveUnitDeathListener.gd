extends PassiveListenerBase
class_name PassiveUnitDeathListener

@export var includeSelf : bool
@export var reqOnlyOnSelfDeath : bool
@export var reqKilledByUser : bool
@export var reqKilledByWeapon : bool
@export var reqOnEnemyTurn : bool
@export var reqOnAlliedTurn : bool
@export var descriptorFilter : DescriptorTemplate
@export var triggerAbilityStack : bool = false



func RegisterListener(_ability : Ability, _map : Map):
	super(_ability, _map)
	if !_map.OnUnitDied.is_connected(OnDeath):
		_map.OnUnitDied.connect(OnDeath)
	pass

func OnDeath(_unitThatDied : UnitInstance, _context : DamageStepResult):
	var passes = CheckRequirements(_unitThatDied, _context)

	if passes && triggerAbilityStack:
		var passiveInstance = PassiveAbilityAction.Construct(ability.ownerUnit, ability)
		passiveInstance.executionStack = ability.executionStack
		passiveInstance.log.actionOriginTile = _unitThatDied.CurrentTile

		if ability.TargetingData != null:
			passiveInstance.log.affectedTiles = ability.TargetingData.GetAffectedTiles(ability.ownerUnit, Map.Current.grid, _unitThatDied.CurrentTile)


		passiveInstance.BuildResults()
		Map.Current.AppendPassiveAction(passiveInstance)

	pass

func CheckRequirements(_unitThatDied : UnitInstance, _context : DamageStepResult):
	var passes = true
	if _context == null:
		passes = false
		return passes

	if !includeSelf && _unitThatDied == ability.ownerUnit:
		passes = false

	if reqOnlyOnSelfDeath && _unitThatDied != ability.ownerUnit:
		passes = false

	if descriptorFilter != null:
		if !_unitThatDied.Template.Descriptors.has(descriptorFilter):
			passes = false

	if reqKilledByUser && _context.Source != ability.ownerUnit:
		passes = false

	if reqKilledByWeapon && _context.AbilityData == null || (_context.AbilityData != null && _context.AbilityData.type != Ability.EAbilityType.Weapon):
		passes = false

	if reqOnAlliedTurn:
		if ability.ownerUnit == null:
			passes = false
		else:
			if ability.ownerUnit.UnitAllegiance != Map.Current.currentTurn:
				passes = false

	if reqOnEnemyTurn:
		if ability.ownerUnit == null:
			passes = false
		else:
			if ability.ownerUnit.UnitAllegiance == Map.Current.currentTurn:
				passes = false

	return passes
