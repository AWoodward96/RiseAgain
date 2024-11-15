extends Resource
class_name LocSettings

# This class is for hard coded localization.

static var Level_Num_Short = "ui_level_num_short"
static var Level_Num = "ui_level_num"

static var Optional_Objective_Block = "Optional Objective: \n{TEXT}"

@export_category("Missing Info")
@export var Missing_CombatEffectIcon : Texture2D
@export var Missing_CombatEffectName : String


@export_category("Text Formatting")
@export var HealColor : Color
@export var DamageColor : Color
@export var CritColor : Color
@export var CollisionColor : Color


func FormatAsHeal(_healAmount : int):
	var htmlHash = HealColor.to_html(false)
	return FormatCenter("[color=#" + htmlHash + "]" + str(_healAmount) + "[/color]")

func FormatForCombat(_damageAmount : int, _collisionAmount : int, _healAmount : int):
	var string = "[color=#{hash}]{dmg}[/color]".format({"hash" : DamageColor.to_html(false), "dmg" : str(_damageAmount)})
	if _collisionAmount != 0:
		string += " [color=#{hash}]{dmg}[/color]".format({"hash" : CollisionColor.to_html(false), "dmg" : str(_collisionAmount)})
	if _healAmount != 0:
		string += " [color=#{hash}]+{dmg}[/color]".format({"hash" : HealColor.to_html(false), "dmg" : str(_healAmount)})
	return FormatCenter(string)

func FormatCenter(_string : String):
	return "[center]" + _string + "[/center]"
