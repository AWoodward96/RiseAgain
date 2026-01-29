extends HBoxContainer
class_name WeaponPanelUI


@export var weaponParent : Control
@export var noWeaponParent : Control
@export var weaponIcon : TextureRect
@export var weaponNameText : Label
@export var weaponDescriptionText : Label
@export var statBlockEntry : Control
@export var accuracyText : Label


func Refresh(_weapon : Ability):
	weaponParent.visible = _weapon != null
	noWeaponParent.visible = _weapon == null

	if _weapon != null:
		weaponIcon.texture = _weapon.icon
		weaponNameText.text = _weapon.loc_displayName
		weaponDescriptionText.text = _weapon.loc_displayDesc
		accuracyText.text = str(_weapon.GetAccuracy())
		var statData = _weapon.StatData
		if statData != null && statData.GrantedStats.size() > 0:
			statBlockEntry.visible = true
			var statDef = statData.GrantedStats[0]
			if statDef != null:
				statBlockEntry.icon.texture = statDef.Template.loc_icon
				statBlockEntry.statValue.text = "%01.0d" % [statDef.Value]
		else:
			statBlockEntry.visible = false
