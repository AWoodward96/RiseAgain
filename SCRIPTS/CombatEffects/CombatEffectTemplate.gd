extends Resource
class_name CombatEffectTemplate

enum EffectTargetType { Source, Targets, Both }

@export_group("Effect Data")
@export var AffectedTargets : EffectTargetType
@export var Turns : int = -1
@export var ImmunityDescriptor : DescriptorTemplate

@export_group("Localization")
@export var show_popup : bool = true
@export var loc_name : String
@export var loc_desc : String
@export var loc_icon : Texture2D


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	pass
