extends Node2D
class_name HealComponent

@export var FlatValue : int
@export var ScalingStat : StatTemplate
@export var ScalingModType : DamageData.ModificationType
@export var ScalingMod : float

@export var ScalesWithUsage : bool = false

var ability : Ability

func DoMod(_val):
	match ScalingModType:
		DamageData.ModificationType.None:
			pass
		DamageData.ModificationType.Additive:
			_val += ScalingMod
		DamageData.ModificationType.Multiplicative:
			_val *= ScalingMod
		DamageData.ModificationType.Divisitive:
			_val /= ScalingMod

	return _val
