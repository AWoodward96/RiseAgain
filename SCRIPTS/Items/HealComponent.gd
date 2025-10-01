extends Node2D
class_name HealComponent

@export var FlatValue : int
@export var ScalingStat : StatTemplate
@export var ScalingModType : DamageData.EModificationType
@export var ScalingMod : float

@export var ScalesWithUsage : bool = false

var ability : Ability

func DoMod(_val):
	match ScalingModType:
		DamageData.EModificationType.None:
			pass
		DamageData.EModificationType.Additive:
			_val += ScalingMod
		DamageData.EModificationType.Multiplicative:
			_val *= ScalingMod
		DamageData.EModificationType.Divisitive:
			_val /= ScalingMod

	return _val
