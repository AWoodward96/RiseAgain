extends Resource
class_name DamageDataResource

## TODO: Figure out if this is used still? If not, delete?

@export var FlatValue : float
@export var AgressiveStat : StatTemplate
@export var AgressiveModType : DamageData.ModificationType
@export var AgressiveMod : float
@export var DefensiveStat : StatTemplate
@export var DefensiveModType : DamageData.ModificationType
@export var DefensiveMod : float


@export_category("Drain")

@export var DamageAffectsUsersHealth : bool = false
# Can be positive OR negative depending on if this heals or hurts the user of this ability
@export var DamageToHealthRatio : float = 0.5


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
