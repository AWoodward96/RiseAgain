extends Node2D
class_name DamageData

enum ModificationType { None, Additive, Multiplicative, Divisitive }

@export var FlatValue : float
@export var AgressiveStat : StatTemplate
@export var AgressiveModType : ModificationType
@export var AgressiveMod : float
@export var DefensiveStat : StatTemplate
@export var DefensiveModType : ModificationType
@export var DefensiveMod : float

@export_category("Drain")
@export var DamageAffectsUsersHealth : bool = false

# Can be positive OR negative depending on if this heals or hurts the user of this ability
# Negative heals, Positive hurts
@export var DamageToHealthRatio : float = 0.5

@export_category("Crit Modifier")
@export_range(-1, 1) var CritModifier : float = 0

@export_category("Vulnerability")
@export var VulerableDescriptors : Array[DescriptorMultiplier]

func DoMod(_val, _mod, _modType : DamageData.ModificationType):
	match _modType:
		DamageData.ModificationType.None:
			pass
		DamageData.ModificationType.Additive:
			_val += _mod
		DamageData.ModificationType.Multiplicative:
			_val = floori(_val * _mod)
		DamageData.ModificationType.Divisitive:
			_val = floori(_val / _mod)
	return _val
