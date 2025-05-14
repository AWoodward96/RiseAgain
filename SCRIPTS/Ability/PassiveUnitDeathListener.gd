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

	# Figure this shit out later
	# Can't run try-execute here because it needs to be in an update loop
	#if passes && triggerAbilityStack:
		#ability.TryExecute()

	pass
