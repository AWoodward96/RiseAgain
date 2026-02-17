extends Resource
class_name CombatEffectTemplate

enum EEffectTargetType { Source, Targets, Both }
enum EStackableType { None = 1,				# This Effect will not stack, and will have a different entry every time
					IncrementOnly = 2,		# This Effect does stack, but doesn't do anything to the turn count
					AddTurns = 3,			# This Effect stacks, and will add the new effect's stack to any existing effect of the same type
					ResetTurnCount = 4 }	# This Effect stacks, and will reset the turn count of any effect of the same type
enum EExpirationType { Normal = 1,			# This Effect gets removed when its turn Count reaches 0
					RemoveStack = 2 }		# This Effect removes one stack when its turn Count reaches 0

enum EDeprecationTime { TurnStart, TurnEnd }



@export_group("Effect Data")
@export var AffectedTargets : EEffectTargetType
@export var Turns : int = -1
@export var ImmunityDescriptor : DescriptorTemplate
@export var StackableType : EStackableType = EStackableType.None
@export var ExpirationType : EExpirationType = EExpirationType.Normal
@export var DeprecationTime : EDeprecationTime = EDeprecationTime.TurnStart

@export_group("Localization")
@export var show_popup : bool = true
@export var loc_name : String
@export var loc_desc : String
@export var loc_icon : Texture2D


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance,  _abilitySource : Ability, _actionLog : ActionLog):
	pass
