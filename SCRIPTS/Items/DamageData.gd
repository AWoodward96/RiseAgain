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


func DoMod(_val, _mod, _modType : ModificationType):
	match _modType:
		ModificationType.None:
			pass
		ModificationType.Additive:
			_val += _mod
		ModificationType.Multiplicative:
			_val *= _mod
		ModificationType.Divisitive:
			_val /= _mod
	return _val
