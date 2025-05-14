extends MultipanelBase


@export var InspectUI : UnitInspectUI
@export var AbilityPrefab : PackedScene
@export var AbilityParent : EntryList
@export var Scroll : ScrollContainer
#
#@export var WeaponPanel : WeaponPanelUI
#@export var TacticalParent : Control
#@export var TacticalPanel : AbilityEntryUI
#@export var AbilityParent : Control
#@export var AbilityPanel : AbilityEntryUI


var unit : UnitInstance
var createdEntries : Array[AbilityEntryUI]

func OnVisiblityChanged():
	if InspectUI != null:
		unit = InspectUI.unit
		if visible:
			Refresh()
			Scroll.set_deferred("scroll_vertical", 0)
		else:
			AbilityParent.ClearEntries()
		#RefreshWeapon()
	pass

func Refresh():
	# First make the weapon
	for abl in unit.Abilities:
		if abl.type == Ability.AbilityType.Weapon:
			var entry = AbilityParent.CreateEntry(AbilityPrefab) as AbilityEntryUI
			entry.Refresh(abl)

	for abl in unit.Abilities:
		if abl.type == Ability.AbilityType.Passive:
			var entry = AbilityParent.CreateEntry(AbilityPrefab) as AbilityEntryUI
			entry.Refresh(abl)

	for abl in unit.Abilities:
		if abl.type == Ability.AbilityType.Tactical:
			var entry = AbilityParent.CreateEntry(AbilityPrefab) as AbilityEntryUI
			entry.Refresh(abl)

	for abl in unit.Abilities:
		if abl.type == Ability.AbilityType.Standard:
			var entry = AbilityParent.CreateEntry(AbilityPrefab) as AbilityEntryUI
			entry.Refresh(abl)

	AbilityParent.FocusFirst()

#func RefreshWeapon():
	#WeaponPanel.Refresh(unit.EquippedWeapon)
	#var foundTactical = false
	#var foundAbility = false
	#for a in unit.Abilities:
		#if a.type == Ability.AbilityType.Tactical:
			#TacticalPanel.Refresh(a)
			#foundTactical = true
		#elif a.type == Ability.AbilityType.Standard:
			#AbilityPanel.Refresh(a)
			#foundAbility = true
#
	#TacticalParent.visible = foundTactical
	#AbilityParent.visible = foundAbility
