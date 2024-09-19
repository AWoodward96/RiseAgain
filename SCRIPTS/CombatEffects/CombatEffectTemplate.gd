extends Resource
class_name CombatEffectTemplate

enum EffectTargetType { Source, Targets, Both }

@export_group("Effect Data")
@export var AffectedTargets : EffectTargetType
@export var Turns : int = -1
@export var ImmunityDescriptor : DescriptorTemplate


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	pass
