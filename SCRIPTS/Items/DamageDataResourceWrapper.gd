extends Resource
class_name DamageDataResource

@export var FlatValue : float
@export var AgressiveStat : StatTemplate
@export var AgressiveModType : DamageData.ModificationType
@export var AgressiveMod : float
@export var DefensiveStat : StatTemplate
@export var DefensiveModType : DamageData.ModificationType
@export var DefensiveMod : float


func DoMod(_val, _mod, _modType : DamageData.ModificationType):
	match _modType:
		DamageData.ModificationType.None:
			pass
		DamageData.ModificationType.Additive:
			_val += _mod
		DamageData.ModificationType.Multiplicative:
			_val *= _mod
		DamageData.ModificationType.Divisitive:
			_val /= _mod
	return _val
