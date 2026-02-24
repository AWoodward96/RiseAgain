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
@export var loc_icon_16px : Texture2D
@export var loc_icon_8px : Texture2D


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance,  _abilitySource : Ability, _actionLog : ActionLog):
	pass

func GetLocIcon(_rectOrSprite):
	if loc_icon_16px == null && loc_icon_8px == null:
		return GameManager.LocalizationSettings.Missing_CombatEffectIcon

	if _rectOrSprite == null:
		return loc_icon_16px

	var size = Vector2.ZERO
	if _rectOrSprite is Sprite2D:
		size = _rectOrSprite.get_rect().size
	if _rectOrSprite is TextureRect:
		size = _rectOrSprite.size


	if loc_icon_16px != null && loc_icon_8px == null:
		return loc_icon_16px

	# In order to stay psudo-pixel-perfect, the calculation is 16*2 and 8*2 for these if checks
	if floori(size.x) % 32 < 4:
		return loc_icon_16px

	if floori(size.x) % 16 < 4:
		return loc_icon_8px

	return loc_icon_16px
