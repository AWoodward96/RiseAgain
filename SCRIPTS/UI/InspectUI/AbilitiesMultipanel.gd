extends MultipanelBase


@export var InspectUI : UnitInspectUI
@export var WeaponPanel : WeaponPanelUI
@export var TacticalParent : Control
@export var TacticalPanel : AbilityEntryUI
@export var AbilityParent : Control
@export var AbilityPanel : AbilityEntryUI


var unit : UnitInstance

func OnVisiblityChanged():
	if InspectUI != null:
		unit = InspectUI.unit
		RefreshWeapon()
	pass

func RefreshWeapon():
	WeaponPanel.Refresh(unit.EquippedWeapon)
	var foundTactical = false
	var foundAbility = false
	for a in unit.Abilities:
		if a.type == Ability.AbilityType.Tactical:
			TacticalPanel.Refresh(a)
			foundTactical = true
		elif a.type == Ability.AbilityType.Standard:
			AbilityPanel.Refresh(a)
			foundAbility = true

	TacticalParent.visible = foundTactical
	AbilityParent.visible = foundAbility
