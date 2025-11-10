extends Node2D
class_name DamageData

enum EModificationType { None, Additive, Multiplicative, Divisitive }
enum EDamageClassification { Physical, Magical, True }

@export var FlatValue : float
@export var AgressiveStat : StatTemplate
@export var AgressiveModType : EModificationType
@export var AgressiveMod : float
@export var DamageType : EDamageClassification = EDamageClassification.Physical
@export var Ignite : int = 0

@export var DamageCantKill : bool = false

@export_category("Extra Data")
@export var DamageAffectsUsersHealth : bool = false

# Can be positive OR negative depending on if this heals or hurts the user of this ability
# Negative heals, Positive hurts
@export var DamageToHealthRatio : float = 0.5

@export_range(-1, 1) var CritModifier : float = 0
@export_range(0, 1) var PercMaxHealthMod : float = 0

@export var VulerableDescriptors : Array[DescriptorMultiplier]

func DoMod(_val, _mod, _modType : DamageData.EModificationType):
	match _modType:
		DamageData.EModificationType.None:
			pass
		DamageData.EModificationType.Additive:
			_val += _mod
		DamageData.EModificationType.Multiplicative:
			_val = floori(_val * _mod)
		DamageData.EModificationType.Divisitive:
			_val = floori(_val / _mod)
	return _val
