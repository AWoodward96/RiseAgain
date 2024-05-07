extends AbilityActionBase
class_name AAPerformCombat

@export var Context : DamageContext
var combatComplete
var ctrl : PlayerController

func _Enter(_context : AbilityContext):
	# This should be handled by CombatControllerState
	# pass the information there
	_context.damageContext = Context
	ctrl = _context.controller
	ctrl.EnterCombatState(_context)
	if !ctrl.OnCombatSequenceComplete.is_connected(OnCombatSequenceComplete):
		ctrl.OnCombatSequenceComplete.connect(OnCombatSequenceComplete)
	combatComplete = false
	return false

func _Execute(_context : AbilityContext):
	return combatComplete

func OnCombatSequenceComplete():
	ctrl.OnCombatSequenceComplete.disconnect(OnCombatSequenceComplete)
	combatComplete = true
