extends Resource
class_name DamageContext

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
		DamageContext.ModificationType.None:
			pass
		DamageContext.ModificationType.Additive:
			_val += _mod
		DamageContext.ModificationType.Multiplicative:
			_val *= _mod
		DamageContext.ModificationType.Divisitive:
			_val /= _mod
	return _val
