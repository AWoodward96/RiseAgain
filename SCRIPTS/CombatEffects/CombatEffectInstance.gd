extends Node
class_name CombatEffectInstance

@export var TurnsRemaining : int

var Template : CombatEffectTemplate
var SourceUnit : UnitInstance
var AffectedUnit : UnitInstance
var AbilitySource : Ability

static func Create(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _template : CombatEffectTemplate, _actionLog : ActionLog):
	if _template == null || _affectedUnit == null:
		return null

	return _template.CreateInstance(_sourceUnit, _affectedUnit, _actionLog)

func IsExpired():
	if TurnsRemaining == 0:
		return true

func OnTurnStart():
	pass
