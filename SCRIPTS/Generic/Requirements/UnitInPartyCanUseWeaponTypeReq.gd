extends RequirementBase
class_name UnitInPartyCanUseWeaponType

@export var WeaponType : DescriptorTemplate

func CheckRequirement(_genericData):
	if WeaponType == null || GameManager.CurrentCampaign == null:
		return true

	for u in GameManager.CurrentCampaign.CurrentRoster:
		for weaponType in u.Template.WeaponDescriptors:
			if weaponType == WeaponType:
				return true
	return false
