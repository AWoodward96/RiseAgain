extends Resource
class_name DamageDataResource

## TODO: Figure out if this is used still? If not, delete?

@export var FlatValue : float
@export var AgressiveStat : StatTemplate
@export var AgressiveModType : DamageData.EModificationType
@export var AgressiveMod : float
@export var DefensiveStat : StatTemplate
@export var DefensiveModType : DamageData.EModificationType
@export var DefensiveMod : float


@export_category("Drain")

@export var DamageAffectsUsersHealth : bool = false
# Can be positive OR negative depending on if this heals or hurts the user of this ability
@export var DamageToHealthRatio : float = 0.5


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
