extends Resource
class_name LocSettings

# This class is for hard coded localization.

static var Level_Num_Short = "ui_level_num_short"
static var Level_Num = "ui_level_num"

static var Optional_Objective_Block = "Optional Objective: \n{TEXT}"

@export_category("Missing Info")
@export var Missing_CombatEffectIcon : Texture2D
@export var Missing_CombatEffectName : String


@export_category("Damage Text Formatting")
@export var HealColor : Color
@export var DamageColor : Color
@export var CritColor : Color
@export var CollisionColor : Color

@export_category("Ability Text Formatting")
@export var RangeAmountTextFormat : String

@export var AbilityTypeWeaponTextShorthand : String
@export var AbilityTypeWeaponColor : Color
@export var AbilityTypeTacticalTextShorthand : String
@export var AbilityTypeTacticalColor : Color
@export var AbilityTypeAbilityTextShorthand : String
@export var AbilityTypeAbilityColor : Color

@export var AbilityTypePassiveTextShorthand : String
@export var AbilityTypePassiveColor : Color

@export var TargetingSimpleText : String
@export var TargetingSimpleColor : Color
@export var TargetingDirectionalText : String
@export var TargetingDirectionalColor : Color
@export var TargetingShapedText : String
@export var TargetingShapedColor : Color
@export var TargetingSelfText : String
@export var TargetingSelfColor : Color
@export var TargetingGlobalText : String
@export var TargetingGlobalColor : Color

@export var AbilitySpeedNormalText : String
@export var AbilitySpeedNormalColor : Color
@export var AbilitySpeedFastText : String
@export var AbilitySpeedFastColor : Color
@export var AbilitySpeedSlowText : String
@export var AbilitySpeedSlowColor : Color


@export_category("Context UI")
@export var waitAction : String = "ui_wait"
@export var openChestAction : String = "ui_openchest"


@export_category("Item Acquired UI")
@export var gotItemConcat : String = "ui_gotitem_concat"
@export var stoleItemConcat : String = "ui_stoleitem_concat"
@export var butSentToConvoyConcat : String = "ui_but_it_was_sent_to_convoy"

func FormatAsHeal(_healAmount : int):
	var htmlHash = HealColor.to_html(false)
	return FormatCenter("[color=#" + htmlHash + "]" + str(_healAmount) + "[/color]")

func FormatForCombat(_damageAmount : int, _collisionAmount : int, _healAmount : int, _forceShow : bool = false):
	var string = ""
	if _damageAmount != 0 || (_damageAmount == 0 && _collisionAmount == 0 && _healAmount == 0 && _forceShow):
		string += "[color=#{hash}]{dmg}[/color] ".format({"hash" : DamageColor.to_html(false), "dmg" : str(_damageAmount)})
	if _collisionAmount != 0:
		string += "[color=#{hash}]{dmg}[/color] ".format({"hash" : CollisionColor.to_html(false), "dmg" : str(_collisionAmount)})
	if _healAmount != 0:
		string += "[color=#{hash}]+{dmg}[/color] ".format({"hash" : HealColor.to_html(false), "dmg" : str(_healAmount)})
	return FormatCenter(string)

func FormatCenter(_string : String):
	return "[center]" + _string + "[/center]"
